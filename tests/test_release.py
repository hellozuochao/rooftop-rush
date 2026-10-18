"""Publication safety and recovery tests: no real GitHub/Roblox mutations."""
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch
import urllib.error

spec = importlib.util.spec_from_file_location('release', Path(__file__).resolve().parents[1] / 'tools/release.py')
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)
EXPECTED = dict(version='v25', commit='a' * 40, repository='owner/game', universe_id=12, place_id=34,
                sha256={name: 'hash' for name in release.ARTIFACTS})


class Store:
    def __init__(self, phase=None, public=False):
        self.state = dict(EXPECTED, phase=phase) if phase else None
        self.exists = bool(phase)
        self.public = public
        self.events = []
        self.fail_receipt = False
        self.fail_finalize = False

    def find(self):
        return {'draft': not self.public} if self.exists else None

    def create(self):
        self.exists = True
        self.events.append('create')

    def read_state(self):
        return copy.deepcopy(self.state)

    def save_state(self, state):
        if self.fail_receipt and state['phase'] == 'roblox_published':
            raise RuntimeError('Receipt persistence failed')
        self.state = copy.deepcopy(state)
        self.events.append(state['phase'])

    def verify_tag(self):
        self.events.append('verify_tag')

    def ensure_artifacts(self, state):
        self.events.append('artifacts')

    def finalize(self, state, notes):
        if self.fail_finalize:
            raise RuntimeError('Finalization failed')
        self.public = True
        self.events.append('finalize')


class RecoveryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        for name in release.ARTIFACTS:
            (root / name).write_bytes(b'EXACT-VERIFIED-BUILD')
        self.root_patch = patch.object(release, 'ROOT', root)
        self.root_patch.start()
        self.addCleanup(self.root_patch.stop)

    def run_release(self, store, publish, recovery=0):
        return release.execute_release(store, EXPECTED, 'notes', 'secret', recovery, publish)

    def test_success_marker_before_post_and_same_bytes(self):
        store = Store()
        def post(data, universe, place, key):
            self.assertEqual(store.state['phase'], 'attempted')
            self.assertIn('artifacts', store.events)
            self.assertEqual(data, b'EXACT-VERIFIED-BUILD')
            self.assertEqual((universe, place), (12, 34))
            return 51
        result = self.run_release(store, post)
        self.assertEqual(result['roblox_version'], 51)
        self.assertTrue(store.public)
        self.assertLess(store.events.index('roblox_published'), store.events.index('finalize'))

    def test_timeout_cannot_repeat_post(self):
        store = Store()
        post = Mock(side_effect=RuntimeError('timeout'))
        with self.assertRaises(RuntimeError):
            self.run_release(store, post)
        with self.assertRaisesRegex(ValueError, 'Do not retry'):
            self.run_release(store, post)
        self.assertEqual(post.call_count, 1)
        self.assertFalse(store.public)

    def test_github_finalize_failure_resumes_without_roblox(self):
        store = Store()
        store.fail_finalize = True
        post = Mock(return_value=52)
        with self.assertRaises(RuntimeError):
            self.run_release(store, post)
        store.fail_finalize = False
        self.run_release(store, post)
        self.assertEqual(post.call_count, 1)
        self.assertTrue(store.public)

    def test_receipt_save_failure_blocks_repeat(self):
        store = Store()
        store.fail_receipt = True
        post = Mock(return_value=53)
        with self.assertRaises(RuntimeError):
            self.run_release(store, post)
        self.assertEqual(store.state['phase'], 'attempted')
        with self.assertRaises(ValueError):
            self.run_release(store, post)
        self.assertEqual(post.call_count, 1)

    def test_verified_manual_recovery_does_not_post(self):
        store = Store('attempted')
        post = Mock()
        result = self.run_release(store, post, recovery=54)
        post.assert_not_called()
        self.assertEqual(result['roblox_version'], 54)
        self.assertTrue(store.public)

    def test_recovery_rejected_without_attempt(self):
        for store in (Store(), Store('prepared')):
            with self.assertRaises(ValueError):
                self.run_release(store, Mock(), recovery=55)

    def test_changed_identity_blocks_publication(self):
        for key, changed in [('commit', 'b' * 40), ('place_id', 999), ('universe_id', 999),
                             ('version', 'v26'), ('repository', 'other/repo'), ('sha256', {})]:
            with self.subTest(key=key):
                store = Store('prepared')
                store.state[key] = changed
                post = Mock()
                with self.assertRaisesRegex(ValueError, 'mismatch'):
                    self.run_release(store, post)
                post.assert_not_called()

    def test_public_release_is_idempotent(self):
        store = Store('roblox_published', public=True)
        store.state['roblox_version'] = 56
        post = Mock()
        self.run_release(store, post)
        post.assert_not_called()
        self.assertNotIn('finalize', store.events)

    def test_marker_storage_failure_prevents_post(self):
        store = Store('prepared')
        store.save_state = Mock(side_effect=RuntimeError('GitHub unavailable'))
        post = Mock()
        with self.assertRaises(RuntimeError):
            self.run_release(store, post)
        post.assert_not_called()

    def test_artifact_mismatch_prevents_post(self):
        store = Store('prepared')
        store.ensure_artifacts = Mock(side_effect=ValueError('artifact mismatch'))
        post = Mock()
        with self.assertRaises(ValueError):
            self.run_release(store, post)
        post.assert_not_called()

    def test_tag_mismatch_prevents_post(self):
        store = Store('prepared')
        store.verify_tag = Mock(side_effect=ValueError('tag mismatch'))
        post = Mock()
        with self.assertRaises(ValueError):
            self.run_release(store, post)
        post.assert_not_called()

    @patch.object(release.urllib.request, 'urlopen')
    def test_api_contract(self, urlopen):
        response = Mock()
        response.read.return_value = json.dumps({'versionNumber': 57}).encode()
        urlopen.return_value.__enter__.return_value = response
        self.assertEqual(release.publish_roblox(b'xml', 12, 34, 'test-key'), 57)
        req = urlopen.call_args.args[0]
        self.assertEqual(req.full_url, 'https://apis.roblox.com/universes/v1/12/places/34/versions?versionType=Published')
        self.assertEqual(req.method, 'POST')
        self.assertEqual(req.data, b'xml')
        self.assertEqual(req.get_header('Content-type'), 'application/xml')

    @patch.object(release.urllib.request, 'urlopen', side_effect=urllib.error.URLError('timeout'))
    def test_api_does_not_retry(self, urlopen):
        with self.assertRaises(RuntimeError):
            release.publish_roblox(b'xml', 12, 34, 'test-key')
        self.assertEqual(urlopen.call_count, 1)

    def test_invalid_receipts_rejected(self):
        for value in (0, -1, True, '7', None):
            with self.assertRaises(ValueError):
                release.next_action(dict(EXPECTED, phase='roblox_published', roblox_version=value), EXPECTED)


if __name__ == '__main__':
    unittest.main()
