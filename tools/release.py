"""Publish one verified build to Roblox and finalize its matching GitHub release.

No automatic retries of Roblox POSTs. A durable draft-release marker prevents
ambiguous failures from publishing the same version twice. Python standard library.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
STATE_ASSET = 'release-state.json'
ARTIFACTS = ('SkylineSample.rbxlx', 'SkylineSample.rbxmx')


def gh(*args):
    return subprocess.check_output(['gh', *args], text=True, stderr=subprocess.PIPE).strip()


def gh_json(*args):
    return json.loads(gh(*args))


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def next_action(state, expected, recovery_version=0):
    """Pure recovery policy; never silently retries a possibly accepted POST."""
    for key in ('version', 'commit', 'repository', 'universe_id', 'place_id', 'sha256'):
        if state.get(key) != expected[key]:
            raise ValueError(f'Release identity mismatch: {key}')
    phase = state.get('phase')
    if phase == 'roblox_published':
        number = state.get('roblox_version')
        if type(number) is not int or number <= 0:
            raise ValueError('Missing valid Roblox version receipt')
        if recovery_version and recovery_version != number:
            raise ValueError('Recovery version conflicts with saved receipt')
        return 'finalize'
    if phase == 'attempted':
        if recovery_version > 0:
            return 'recover'
        raise ValueError('Roblox upload was attempted. Do not retry it automatically. Verify Roblox version history and the exact deployed build, then supply recovery_version, or investigate manually.')
    if phase == 'prepared' and recovery_version == 0:
        return 'publish'
    raise ValueError('Invalid release phase or recovery input')


def publish_roblox(data, universe_id, place_id, api_key):
    request = urllib.request.Request(
        f'https://apis.roblox.com/universes/v1/{universe_id}/places/{place_id}/versions?versionType=Published',
        data=data, method='POST',
        headers={'x-api-key': api_key, 'Content-Type': 'application/xml'},
    )
    # Deliberately one request only: a timeout may still mean Roblox accepted it.
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            result = json.load(response)
    except (urllib.error.URLError, TimeoutError, ValueError) as exc:
        raise RuntimeError('Roblox upload failed or its outcome is unknown. The attempt marker remains; inspect Roblox before recovery.') from None
    number = result.get('versionNumber')
    if type(number) is not int or number <= 0:
        raise RuntimeError('Roblox response has no valid versionNumber; manual recovery required')
    return number


class GitHubRelease:
    def __init__(self, repo, version, commit):
        self.repo, self.version, self.commit = repo, version, commit

    def find(self):
        try:
            return gh_json('api', f'repos/{self.repo}/releases/tags/{self.version}')
        except subprocess.CalledProcessError as exc:
            if 'HTTP 404' in (exc.stderr or ''):
                return None
            raise

    def create(self):
        # Draft releases may not create the Git ref until publication. Pin it first.
        try:
            gh_json('api', f'repos/{self.repo}/git/ref/tags/{self.version}')
        except subprocess.CalledProcessError as exc:
            if 'HTTP 404' not in (exc.stderr or ''):
                raise
            gh('api', f'repos/{self.repo}/git/refs', '-X', 'POST',
               '-f', f'ref=refs/tags/{self.version}', '-f', f'sha={self.commit}')
        else:
            actual = gh_json('api', f'repos/{self.repo}/commits/{self.version}')['sha']
            if actual != self.commit:
                raise ValueError('Existing tag points to another commit; choose a new version')
        gh('release', 'create', self.version, '--repo', self.repo, '--target', self.commit,
           '--draft', '--title', f'Rooftop Rush {self.version}',
           '--notes', 'Release preparation in progress. Not yet confirmed published to Roblox.')

    def verify_tag(self):
        actual = gh_json('api', f'repos/{self.repo}/commits/{self.version}')['sha']
        if actual != self.commit:
            raise ValueError('Git tag does not point to the verified build commit')

    def read_state(self):
        release = self.find()
        if not any(a['name'] == STATE_ASSET for a in release['assets']):
            raise ValueError('Existing release has no publication ledger; inspect it manually before proceeding')
        with tempfile.TemporaryDirectory() as directory:
            gh('release', 'download', self.version, '--repo', self.repo,
               '--pattern', STATE_ASSET, '--dir', directory)
            return json.loads((Path(directory) / STATE_ASSET).read_text())

    def save_state(self, state):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / STATE_ASSET
            path.write_text(json.dumps(state, indent=2) + '\n')
            gh('release', 'upload', self.version, str(path), '--repo', self.repo, '--clobber')

    def ensure_artifacts(self, state):
        names = {a['name'] for a in self.find()['assets']}
        for name in ARTIFACTS:
            if name not in names:
                gh('release', 'upload', self.version, str(ROOT / name), '--repo', self.repo)
            else:
                with tempfile.TemporaryDirectory() as directory:
                    gh('release', 'download', self.version, '--repo', self.repo,
                       '--pattern', name, '--dir', directory)
                    if digest(Path(directory) / name) != state['sha256'][name]:
                        raise ValueError(f'Frozen release artifact mismatch: {name}')

    def finalize(self, state, notes):
        body = notes + '\n\n## Publication receipt\n\n' + '\n'.join([
            f"- Game version: `{state['version']}`",
            f"- Source commit: `{state['commit']}`",
            f"- Roblox Universe ID: `{state['universe_id']}`",
            f"- Roblox Place ID: `{state['place_id']}`",
            f"- Roblox place version: `{state['roblox_version']}`",
            f"- [Play](https://www.roblox.com/games/{state['place_id']})",
            '- SHA-256 values and recovery status: attached `release-state.json`.',
            '- Existing Roblox servers may still run an older version.',
        ])
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'notes.md'
            path.write_text(body + '\n')
            gh('release', 'edit', self.version, '--repo', self.repo,
               '--notes-file', str(path), '--draft=false')


def execute_release(store, expected, notes, api_key, recovery_version=0, publisher=publish_roblox):
    existing = store.find()
    if existing is None:
        if recovery_version:
            raise ValueError('Cannot recover a release without an existing attempt marker')
        store.create()
        state = dict(expected, phase='prepared')
        store.save_state(state)
    else:
        state = store.read_state()
    action = next_action(state, expected, recovery_version)
    if existing is not None and not existing['draft']:
        if action != 'finalize':
            raise ValueError('Public release lacks a completed Roblox receipt')
        store.verify_tag()
        print('Already published; nothing changed.')
        return state
    store.verify_tag()
    store.ensure_artifacts(state)
    if action == 'publish':
        # Store the durable attempt marker BEFORE any Roblox request.
        state = dict(state, phase='attempted')
        store.save_state(state)
        number = publisher((ROOT / ARTIFACTS[0]).read_bytes(),
                           state['universe_id'], state['place_id'], api_key)
        state = dict(state, phase='roblox_published', roblox_version=number)
        store.save_state(state)
    elif action == 'recover':
        state = dict(state, phase='roblox_published', roblox_version=recovery_version,
                     recovery='Maintainer verified Roblox version history and deployed build')
        store.save_state(state)
    store.finalize(state, notes)
    return state


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--version', required=True)
    parser.add_argument('--recovery-version', type=int, default=0)
    args = parser.parse_args()
    if not re.fullmatch(r'v[1-9][0-9]*', args.version) or args.recovery_version < 0:
        raise ValueError('Invalid version input')
    if args.version != (ROOT / 'VERSION').read_text().strip():
        raise ValueError('Requested version differs from VERSION in this commit')
    repo = os.environ['GITHUB_REPOSITORY']
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repo):
        raise ValueError('Invalid repository')
    commit = os.environ['RELEASE_COMMIT']
    if not re.fullmatch(r'[0-9a-f]{40}', commit):
        raise ValueError('Invalid commit SHA')
    if subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip() != commit:
        raise ValueError('Checkout differs from release commit')
    if subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no'], text=True).strip():
        raise ValueError('Tracked source changes must be committed before release')
    universe_id, place_id = int(os.environ['ROBLOX_UNIVERSE_ID']), int(os.environ['ROBLOX_PLACE_ID'])
    if universe_id <= 0 or place_id <= 0:
        raise ValueError('Roblox IDs must be positive')
    api_key = os.environ.get('ROBLOX_API_KEY', '')
    if not api_key:
        raise ValueError('Missing ROBLOX_API_KEY secret')
    notes = (ROOT / 'releases' / f'{args.version}.md').read_text()
    for artifact in ARTIFACTS:
        doc = ET.parse(ROOT / artifact)
        info = next(i for i in doc.iter('Item') if i.findtext('./Properties/string[@name="Name"]') == 'BuildInfo')
        values = {i.findtext('./Properties/string[@name="Name"]'): i.findtext('./Properties/string[@name="Value"]') for i in info.findall('Item')}
        if values != {'Version': args.version, 'Commit': commit}:
            raise ValueError(f'Build metadata mismatch: {artifact}')
    expected = dict(version=args.version, commit=commit, repository=repo,
                    universe_id=universe_id, place_id=place_id,
                    sha256={name: digest(ROOT / name) for name in ARTIFACTS})
    state = execute_release(GitHubRelease(repo, args.version, commit), expected, notes, api_key, args.recovery_version)
    print(json.dumps({k: state[k] for k in ('version', 'commit', 'place_id', 'roblox_version')}))


if __name__ == '__main__':
    try:
        main()
    except subprocess.CalledProcessError:
        raise SystemExit('GitHub command failed. Inspect the draft release and rerun the SAME commit; do not remove its attempt marker.')
    except (ValueError, RuntimeError, KeyError, OSError) as exc:
        raise SystemExit(str(exc))
