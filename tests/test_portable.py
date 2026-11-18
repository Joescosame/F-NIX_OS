import importlib.util
import io
import pathlib
import subprocess
import sys
import tempfile
import unittest

ROOT=pathlib.Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('portable',ROOT/'tools/portable-qa.py')
p=importlib.util.module_from_spec(spec); spec.loader.exec_module(p)

class PortableTests(unittest.TestCase):
    def test_static_casper_order_preserved_and_extended(self):
        original='/scripts/casper-bottom/05mountpoints "$@"\n/scripts/casper-bottom/99casperboot "$@"\n'
        result=p.extend_casper_order(original)
        self.assertTrue(result.startswith(original))
        self.assertEqual(result.count('/scripts/casper-bottom/99fenix-qa "$@"'),1)
        for invalid in ('', 'run-parts /scripts/casper-bottom',result):
            with self.assertRaises(ValueError): p.extend_casper_order(invalid)

    def test_padding_precedes_external_writer(self):
        with tempfile.TemporaryDirectory() as tmp:
            path=pathlib.Path(tmp)/'initrd'
            path.write_bytes(b'xx')
            with path.open('ab') as output:
                p.align_cpio(output)
                subprocess.run([sys.executable,'-c','import sys; sys.stdout.buffer.write(b"070701")'],
                               stdout=output,check=True)
            self.assertEqual(path.read_bytes(),b'xx\0\0' + b'070701')

    def test_newc_extension_aligned_after_any_original_length(self):
        for size in (0, 1, 2, 3, 4, 82518462):
            # Não altera bytes originais nem adiciona um bloco quando já alinhado.
            output=io.BytesIO(b'x'*size); output.seek(0,2)
            p.align_cpio(output)
            self.assertEqual(output.tell()%4,0)
            self.assertEqual(output.tell(),size+(-size%4))
            self.assertEqual(output.getvalue()[:size],b'x'*size)
            self.assertEqual(output.getvalue()[size:],b'\0'*(-size%4))

    def test_no_iso_in_any_installed_boot_and_same_disk(self):
        disk=pathlib.Path('/qa/destino.qcow2')
        for mode in ('legacy','uefi'):
            for ctrl in ('ide','sata','nvme'):
                cmd=p.command(disk,mode,ctrl,'tcg',pathlib.Path('/tmp/qmp'),pathlib.Path('/qa/serial.log'),varfile=pathlib.Path('/qa/vars'))
                self.assertNotIn('-cdrom',cmd)
                self.assertNotIn('-kernel',cmd)
                self.assertIn(f'file={disk},format=qcow2,if=none,id=destino',cmd)
                self.assertIn('none',cmd)
                self.assertNotIn('/dev/sda',' '.join(cmd))
        for disk in (pathlib.Path('/dev/sda'),pathlib.Path('/qa/mal,formado/destino.qcow2')):
            with self.assertRaises(ValueError): p.command(disk,'legacy','ide','tcg',pathlib.Path('/qmp'),pathlib.Path('/log'))

    def test_guest_destructive_path_is_qa_guarded(self):
        text=(ROOT/'tools/portable/guest-install.sh').read_text()
        self.assertLess(text.index('FENIX-QA-PORTABLE'),text.index('debconf-set-selections'))
        self.assertLess(text.index('FENIXQA001'),text.index('debconf-set-selections'))
        self.assertIn('34359738368',text)
        success=(ROOT/'tools/portable/guest-success.sh').read_text()
        self.assertLess(success.index('FENIX-QA-PORTABLE'),success.index('grub-install'))
        self.assertIn('--removable --no-nvram',success)

if __name__=='__main__': unittest.main()
