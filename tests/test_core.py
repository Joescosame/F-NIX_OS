import ast
import csv
import importlib.util
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import types
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

def module(name, filename):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'tools' / filename)
    m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
    return m

release = module('release', 'release.py')
patcher = module('patcher', 'patch-timezone.py')
qemu = module('qemu', 'qemu-qa.py')
approval = module('approval', 'check-approval.py')

class BuildSafetyTests(unittest.TestCase):
    def test_installer_manifests_keep_profile_and_language(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=pathlib.Path(tmp); casper=root/'casper'; casper.mkdir()
            (casper/'filesystem.manifest').write_text('ubiquity 1\nyad 1\nlanguage-pack-pt 1\nbase 1\n')
            (casper/'filesystem.manifest-remove').write_text('ubiquity\nlanguage-pack-pt\n')
            cfg=root/'rootfs/usr/local/share/fenix'; cfg.mkdir(parents=True)
            (cfg/'required-packages.txt').write_text('yad\nlanguage-pack-pt\n')
            subprocess.run([sys.executable,str(ROOT/'tools/update-manifests.py'),str(casper),str(root/'rootfs')],check=True)
            self.assertEqual((casper/'filesystem.manifest-remove').read_text(),'ubiquity\n')
            self.assertIn('language-pack-pt 1',(casper/'filesystem.manifest-desktop').read_text())
            self.assertNotIn('ubiquity',(casper/'filesystem.manifest-desktop').read_text())
            (cfg/'required-packages.txt').write_text('ausente\n')
            result=subprocess.run([sys.executable,str(ROOT/'tools/update-manifests.py'),str(casper),str(root/'rootfs')],capture_output=True)
            self.assertNotEqual(result.returncode,0)

    def test_approval_rejects_unexecuted_and_different_iso(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=pathlib.Path(tmp); (root/'qa').mkdir(); (root/'dist').mkdir()
            (root/'dist'/release.NAME).write_bytes(b'fixture')
            m=json.loads((ROOT/'config/aprovacao.example.json').read_text(encoding='utf-8'))
            (root/'qa/aprovacao.json').write_text(json.dumps(m))
            with self.assertRaises(ValueError): approval.check(root)
            m['iso_sha256']=release.digest(root/'dist'/release.NAME)
            (root/'qa/aprovacao.json').write_text(json.dumps(m))
            with self.assertRaises(ValueError): approval.check(root)
            for key in approval.REQUIRED: m['tests'][key]={'status':'PASSOU','evidence':['../fora']}
            (root/'qa/aprovacao.json').write_text(json.dumps(m))
            with self.assertRaises(ValueError): approval.check(root)

    def test_no_physical_disk_arguments_in_harness(self):
        source=(ROOT/'tools/qemu-qa.py').read_text(encoding='utf-8')
        self.assertNotIn("add_argument('--disk'",source)
        self.assertNotIn("add_argument('--drive'",source)
        cmd=qemu.command('install',pathlib.Path('/candidate.iso'),pathlib.Path('/qa/destino.qcow2'),pathlib.Path('/seabios'),8192)
        self.assertIn('-cdrom',cmd)
        self.assertIn('file='+str(pathlib.Path('/qa/destino.qcow2'))+',format=qcow2,if=ide',cmd)
        self.assertEqual(cmd[cmd.index('-m')+1],'8192')
        qemu.validate_image_info({'format':'qcow2'})
        for info in ({'format':'raw'}, {'format':'qcow2','backing-filename':'/dev/sda'},
                     {'format':'qcow2','format-specific':{'data':{'data-file':'/dev/sda'}}}):
            with self.assertRaises(ValueError): qemu.validate_image_info(info)

class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = pathlib.Path(self.tmp.name)
        self.iso = self.root / release.NAME
        self.data = bytes(range(256))*100 + b'final'
        self.iso.write_bytes(self.data)
        self.parts = self.root / 'parts'
        self.manifest = release.split(self.iso, self.parts, 4096)

    def test_roundtrip_and_no_overwrite(self):
        self.assertEqual(release.join(self.parts).read_bytes(), self.data)
        with self.assertRaises(FileExistsError): release.join(self.parts)

    def test_verify_rejects_wrong_final_hash_without_joining(self):
        self.assertEqual(release.verify(self.parts), self.manifest)
        self.manifest['sha256'] = '0'*64
        (self.parts/'manifesto.json').write_text(json.dumps(self.manifest))
        with self.assertRaises(ValueError): release.verify(self.parts)
        self.assertFalse((self.parts/release.NAME).exists())

    def test_corruption_is_rejected(self):
        p = self.parts / self.manifest['parts'][0]['name']
        p.write_bytes(b'x'*p.stat().st_size)
        with self.assertRaises(ValueError): release.join(self.parts)
        self.assertFalse((self.parts / release.NAME).exists())

    def test_missing_part_is_rejected(self):
        (self.parts / self.manifest['parts'][1]['name']).unlink()
        with self.assertRaises(FileNotFoundError): release.join(self.parts)

    def test_traversal_order_and_oversize_rejected(self):
        for value in ('../disco', 'C:\\disco', release.NAME+'.part002'):
            m = json.loads(json.dumps(self.manifest)); m['parts'][0]['name'] = value
            with self.assertRaises(ValueError): release.validate(m)
        m = json.loads(json.dumps(self.manifest)); m['parts'][0]['size'] = 2**31
        with self.assertRaises(ValueError): release.validate(m)

    @unittest.skipUnless(shutil.which('powershell'), 'Windows PowerShell 5.1 ausente')
    def test_windows_powershell_51_roundtrip(self):
        cmd = ['powershell','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',
               str(ROOT/'tools/JUNTAR_ISO.ps1'), '-Pasta', str(self.parts)]
        subprocess.run(cmd, check=True, capture_output=True)
        self.assertEqual((self.parts/release.NAME).read_bytes(), self.data)
        self.assertNotEqual(subprocess.run(cmd, capture_output=True).returncode, 0)

    @unittest.skipUnless(shutil.which('powershell'), 'Windows PowerShell 5.1 ausente')
    def test_windows_powershell_rejects_corruption(self):
        (self.parts/self.manifest['parts'][0]['name']).write_bytes(b'x'*4096)
        result = subprocess.run(['powershell','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',
               str(ROOT/'tools/JUNTAR_ISO.ps1'), '-Pasta', str(self.parts)], capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.parts/release.NAME).exists())

class TimezoneTests(unittest.TestCase):
    def setUp(self):
        self.source = (ROOT/'tests/fixtures/ubi-timezone.py').read_text(encoding='utf-8')

    def callback(self, source):
        tree = ast.parse(source)
        cls = next(n for n in tree.body if isinstance(n, ast.ClassDef) and n.name=='PageGtk')
        node = next(n for n in cls.body if isinstance(n, ast.FunctionDef) and n.name=='geoname_cb')
        self.Error = type('NetworkError', (Exception,), {})
        namespace = dict(GLib=types.SimpleNamespace(Error=self.Error, source_remove=lambda x: None),
                         Soup=types.SimpleNamespace(Status=types.SimpleNamespace(OK=200)),
                         Gio=types.SimpleNamespace(IOErrorEnum=types.SimpleNamespace(CANCELLED=1)),
                         syslog=types.SimpleNamespace(syslog=lambda x: None), json=json)
        exec(compile(ast.Module(body=[node], type_ignores=[]), '<callback>', 'exec'), namespace)
        return namespace['geoname_cb']

    def invoke(self, callback, payload=None, error=False, status=200, text='Recente'):
        model=[]
        class Session:
            def send_and_read_finish(inner, result):
                if error:
                    e=self.Error(); e.code=1; raise e
                return None if payload is None else types.SimpleNamespace(get_data=lambda: payload)
        completion=types.SimpleNamespace(set_model=lambda m: model.append(('aplicado',)))
        owner=types.SimpleNamespace(geoname_timeout_id=None, geoname_cache={},
              geoname_add_tzdb=lambda t,m: m.append(['fallback-local']),
              city_entry=types.SimpleNamespace(get_text=lambda: text,get_completion=lambda: completion))
        callback(owner, Session(), None, (types.SimpleNamespace(get_status=lambda: status, get_reason_phrase=lambda: 'erro'), 'Recente', model))
        return model, owner

    def test_original_reproduces_none_get_data(self):
        with self.assertRaises(AttributeError): self.invoke(self.callback(self.source), error=True)

    def test_patch_handles_cancelled_empty_and_malformed(self):
        cb = self.callback(patcher.patch(self.source))
        for args in ({'error':True}, {}, {'payload':b'null'}, {'payload':b'{}'},
                     {'payload':b'[{"name":"incompleto"}]'}, {'payload':b'not json'},
                     {'payload':b'\xff'}, {'status':503}):
            model,owner = self.invoke(cb, **args)
            self.assertIn(['fallback-local'], model)
            self.assertEqual(owner.geoname_cache,{})

    def test_valid_reply_and_stale_reply(self):
        cb=self.callback(patcher.patch(self.source))
        payload=json.dumps([dict(name='São Paulo',admin1='SP',country='BR',latitude='-23',longitude='-46')]).encode()
        model,owner=self.invoke(cb,payload=payload)
        self.assertIn('Recente',owner.geoname_cache)
        self.assertIn(('aplicado',),model)
        model,_=self.invoke(cb,payload=payload,text='Outro')
        self.assertNotIn(('aplicado',),model)

    def test_patch_idempotent_and_unknown_layout_rejected(self):
        result=patcher.patch(self.source)
        self.assertEqual(patcher.patch(result),result)
        with self.assertRaises(ValueError): patcher.patch(self.source.replace('_bytes.get_data()', '_bytes.bytes()'))

class OfflineTests(unittest.TestCase):
    def test_history_csv_jsonl_and_limits(self):
        with tempfile.TemporaryDirectory() as tmp:
            cmd=[sys.executable,str(ROOT/'scripts/historico-sensores.py'),'--duration','1','--interval','0.5','--output-dir',tmp]
            subprocess.run(cmd,check=True,capture_output=True)
            rows=[json.loads(line) for line in next(pathlib.Path(tmp).glob('*.jsonl')).read_text().splitlines()]
            with next(pathlib.Path(tmp).glob('*.csv')).open(newline='',encoding='utf-8') as f: csvrows=list(csv.DictReader(f))
            self.assertGreaterEqual(len(rows),2); self.assertEqual(len(rows),len(csvrows))
            self.assertEqual([r['timestamp'] for r in rows],[r['timestamp'] for r in csvrows])
            result=subprocess.run(cmd+['--interval','0'],capture_output=True)
            self.assertNotEqual(result.returncode,0)

    def test_qemu_reboot_has_no_iso_and_offline_no_network(self):
        cmd=qemu.command('reboot',pathlib.Path('/iso'),pathlib.Path('/qa/test.qcow2'),pathlib.Path('/bios'))
        self.assertNotIn('-cdrom',cmd); self.assertNotIn('/iso',cmd)
        self.assertEqual(cmd[cmd.index('-nic')+1],'none')
        self.assertEqual(cmd[cmd.index('-smp')+1],'2')
        self.assertEqual(cmd[cmd.index('-bios')+1],str(pathlib.Path('/bios')))
        with self.assertRaises(ValueError): qemu.command('install',pathlib.Path('/iso'),pathlib.Path('/a,file=/dev/sda'),pathlib.Path('/bios'))

    @unittest.skipUnless(sys.platform.startswith('linux'), 'Snapshot requer utilitários Linux')
    def test_snapshot_hash_manifest(self):
        with tempfile.TemporaryDirectory() as tmp:
            env=dict(os.environ,HOME=tmp,FENIX_NO_GUI='1')
            subprocess.run(['bash',str(ROOT/'scripts/salvar-snapshot.sh')],env=env,check=True,capture_output=True)
            folder=next((pathlib.Path(tmp)/'TestesPC/snapshots').iterdir())
            subprocess.run(['sha256sum','-c','SHA256SUMS.txt'],cwd=folder,check=True,capture_output=True)

if __name__ == '__main__': unittest.main()
