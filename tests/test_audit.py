import importlib.util
import os
import pathlib
import subprocess
import sys
import tempfile
import unittest
import yaml

ROOT = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('boot', ROOT/'tools/check-boot.py')
boot = importlib.util.module_from_spec(spec)
spec.loader.exec_module(boot)

class AuditTests(unittest.TestCase):
    def test_boot_requires_enabled_bios_and_mbr(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=pathlib.Path(tmp)/'report.txt'
            valid='System area summary: MBR isohybrid GPT\nEl Torito boot img : 1 BIOS y none 0x0000 0x00 4 117\n'
            p.write_text(valid)
            signature=boot.signature(p)
            p.write_text(valid.replace('BIOS y','BIOS n'))
            with self.assertRaises(SystemExit): boot.signature(p)
            p.write_text(valid.replace('MBR isohybrid GPT','GPT'))
            with self.assertRaises(SystemExit): boot.signature(p)
            p.write_text(valid.replace('0x0000','0x07c0'))
            self.assertNotEqual(signature,boot.signature(p))

    def test_manual_workflow_has_no_paid_runner_or_default_upload(self):
        d=yaml.safe_load((ROOT/'.github/workflows/build.yml').read_text(encoding='utf-8'))
        trigger=d.get('on',d.get(True))
        self.assertEqual(set(trigger),{'workflow_dispatch'})
        inputs=trigger['workflow_dispatch']['inputs']
        self.assertEqual(inputs['runner']['options'],['ubuntu-24.04','self-hosted'])
        self.assertIs(inputs['guardar_artefato']['default'],False)
        self.assertIs(inputs['confirmar_recursos']['default'],False)
        uploads=[s for s in d['jobs']['build']['steps'] if 'actions/upload-artifact@' in s.get('uses','')]
        self.assertEqual(len(uploads),1)
        self.assertEqual(uploads[0]['if'],'${{ inputs.guardar_artefato }}')

    @unittest.skipUnless(sys.platform.startswith('linux'), 'Proteção do runner requer Bash/Linux')
    def test_cleanup_refuses_non_hosted_environment(self):
        env=dict(os.environ,GITHUB_ACTIONS='false',RUNNER_ENVIRONMENT='self-hosted')
        p=subprocess.run(['bash',str(ROOT/'tools/prepare-hosted-runner.sh')],env=env,capture_output=True)
        self.assertNotEqual(p.returncode,0)
        self.assertIn(b'BLOQUEADO',p.stderr)

if __name__ == '__main__': unittest.main()
