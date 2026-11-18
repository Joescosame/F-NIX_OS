import copy
import importlib.util
import json
import os
import pathlib
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
def modulo(nome,path):
    spec=importlib.util.spec_from_file_location(nome,ROOT/path)
    m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m); return m
d=modulo('diagnostico','scripts/diagnostico-upgrade.py')
p=modulo('plataforma','tools/platform-check.py')
b=modulo('boot','tools/check-boot.py')
a=modulo('aprovacao','tools/check-approval.py')

class UpgradeTests(unittest.TestCase):
    def fixture(self,root,nome,valor):
        path=root/nome; path.parent.mkdir(parents=True,exist_ok=True); path.write_text(valor)

    def test_collect_fixture_private_fields_and_missing_sensors(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=pathlib.Path(tmp)
            for nome,valor in {'proc/cpuinfo':'model name : CPU simulada\nmodel name : CPU simulada',
                               'proc/meminfo':'MemTotal: 8000000 kB',
                               'sys/class/dmi/id/board_name':'Placa simulada',
                               'sys/class/dmi/id/product_serial':'SEGREDO-SERIAL',
                               'sys/class/net/eth0/address':'SEGREDO-MAC',
                               'sys/bus/pci/devices/slot-simulado/class':'0x030000',
                               'sys/bus/pci/devices/slot-simulado/vendor':'0x1234',
                               'sys/block/sda/device/model':'SSD simulado',
                               'sys/block/sda/size':'1000'}.items(): self.fixture(root,nome,valor)
            dados=d.coletar(root)
            self.assertNotIn('SEGREDO',json.dumps(dados))
            self.assertIn('gpu',{i['categoria'] for i in dados['componentes']})
            self.assertTrue(all(i['teste_funcional']=='NÃO EXECUTADO' for i in dados['componentes']))
            self.assertEqual(next(i for i in dados['componentes'] if i['categoria']=='processador')['atributos']['processadores_logicos'],2)
            pasta=root/'salvos'; path=d.salvar(dados,pasta)
            self.assertEqual(d.carregar(path),dados)
            if os.name=='posix': self.assertEqual(path.stat().st_mode & 0o777,0o600)

    def test_compare_changes_driver_and_relocation(self):
        antes={'schema':1,'componentes':[d.componente('gpu','slot1',{'device':'a'},'driver-a'),
                                       d.componente('usb','porta1',{'device':'mouse'})]}
        depois=copy.deepcopy(antes)
        depois['componentes'][0]=d.componente('gpu','slot1',{'device':'b'},'driver-b')
        depois['componentes'][1]['localizacao']='porta2'
        r=d.comparar(antes,depois)
        for key in ('adicionados','removidos','possiveis_substituicoes','drivers_alterados'):
            self.assertEqual(len(r[key]),1,key)
        self.assertFalse(any(d.comparar(antes,antes)[k] for k in ('adicionados','removidos','possiveis_substituicoes','drivers_alterados')))

    def test_unavailable_and_schema_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(d.coletar(pathlib.Path(tmp))['componentes'],[])
        for dados in ([], {'schema':1,'componentes':[None]}, {'schema':2,'componentes':[]},{'schema':1,'componentes':[{},{}]}):
            with self.assertRaises(ValueError): d.validar(dados)
        item=d.componente('gpu','slot',{})
        with self.assertRaises(ValueError): d.validar({'schema':1,'componentes':[item,item]})

    def test_profiles_preserve_errors_and_dual_boot_structure(self):
        self.assertTrue(p.validar('legacy','dos','legacy','dos'))
        self.assertTrue(p.validar('legacy','gpt','legacy','gpt'))
        self.assertTrue(p.validar('uefi','gpt','uefi','gpt',True))
        for args in [('uefi','gpt','legacy','gpt',True),('uefi','gpt','uefi','gpt',False),('legacy','dos','legacy','gpt',False)]:
            with self.assertRaises(ValueError): p.validar(*args)
        with tempfile.TemporaryDirectory() as tmp:
            path=pathlib.Path(tmp)/'boot.txt'
            text='System area summary: MBR GPT\nEl Torito boot img : 1 BIOS y none 0x0000 0x00 4 117\n'
            path.write_text(text)
            with self.assertRaises(SystemExit): b.signature(path,('BIOS','UEFI'))
            path.write_text(text+'El Torito boot img : 2 UEFI y none 0x0000 0x00 8 200\n')
            self.assertEqual(len(b.signature(path,('BIOS','UEFI'))),2)

    def test_cancelled_integrations_absent_from_runtime(self):
        for folder in ('scripts','assets','config'):
            for path in (ROOT/folder).glob('*'):
                if path.is_file():
                    text=path.read_text(encoding='utf-8').lower()
                    for cancelled in ('newelle','deepseek','waydroid','mangohud','goverlay'):
                        self.assertNotIn(cancelled,text,str(path))
        stage=(ROOT/'scripts/stage-into-root.sh').read_text()
        self.assertIn('diagnostico-upgrade.py',stage)

    def test_portable_approval_rejects_different_disks(self):
        import hashlib
        with tempfile.TemporaryDirectory() as tmp:
            root=pathlib.Path(tmp); (root/'qa').mkdir(); (root/'dist').mkdir()
            (root/'dist/FENIX-OS-Legacy-amd64.iso').write_bytes(b'simulada')
            m={'perfil':'portable-gpt-v1','disco_campanha':'vm-a',
               'iso_sha256':hashlib.sha256(b'simulada').hexdigest(), 'tests':{}}
            for nome in a.PORTABLE: m['tests'][nome]={'status':'PASSOU','evidence':['prova.txt'],'disco_campanha':'vm-a'}
            (root/'qa/prova.txt').write_text('Fixture, não prova de boot real')
            (root/'qa/aprovacao.json').write_text(json.dumps(m))
            a.check(root)
            m['tests']['uefi_disk_boot']['disco_campanha']='vm-b'
            (root/'qa/aprovacao.json').write_text(json.dumps(m))
            with self.assertRaises(ValueError): a.check(root)

if __name__=='__main__': unittest.main()
