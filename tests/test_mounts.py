"""Regressão real de submontagem e ocupação; somente namespace descartável."""
import pathlib
import subprocess
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

class MountTests(unittest.TestCase):
    @unittest.skipUnless(sys.platform.startswith('linux'), 'Requer Linux e mount namespace')
    def test_nested_mount_and_busy_mount(self):
        script = r'''
set -Eeuo pipefail
mount --make-rprivate /
tmp=$(mktemp -d)
trap 'umount -R "$tmp" 2>/dev/null || true; rmdir "$tmp"' EXIT
mount -t tmpfs tmpfs "$tmp"
mkdir "$tmp/child"
mount -t tmpfs tmpfs "$tmp/child"
bash "$1" "$tmp"
! mountpoint -q "$tmp"
mount -t tmpfs tmpfs "$tmp"
(cd "$tmp"; exec sleep 60) &
holder=$!
sleep 0.2
if bash "$1" "$tmp"; then kill "$holder"; exit 1; fi
mountpoint -q "$tmp"
kill "$holder"
wait "$holder" || true
bash "$1" "$tmp"
'''
        result = subprocess.run(['sudo', 'unshare', '--mount', '--fork', 'bash', '-c',
                                 script, 'regression', str(ROOT/'tools/unmount-tree.sh')],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout+result.stderr)

if __name__ == '__main__': unittest.main()
