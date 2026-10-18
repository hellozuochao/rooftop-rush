"""Build and verify production sources; Studio integration tests run separately."""
import argparse
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument("--luau-bin", type=pathlib.Path, required=True, help="Directory containing luau and luau-compile")
a = p.parse_args()
def run(*args):
    subprocess.run([str(x) for x in args], cwd=ROOT, check=True)
run(sys.executable, ROOT / "tools/build_place.py")
run(sys.executable, ROOT / "tests/check_build.py")
run(a.luau_bin / "luau-compile", "--null", *sorted((ROOT / "src").rglob("*.luau")), ROOT / "tests/Suite.server.luau", ROOT / "tests/Suite.client.luau")
run(a.luau_bin / "luau", ROOT / "tests/core.spec.luau")
print("PASS: offline checks. Studio integration and real-device tests are separate.")
