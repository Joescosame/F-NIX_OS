#!/usr/bin/env python3
"""Inventário local sem telemetria; detecção não equivale a teste funcional."""
import argparse
import datetime
import json
import os
import pathlib
import re
import shutil
import subprocess
import tempfile
import uuid

SCHEMA = 1
SUGESTOES = {
    'processador': 'Compare carga, temperatura e estabilidade com uma tarefa conhecida.',
    'memoria': 'Execute teste de memória em mídia de recuperação; salve o trabalho antes.',
    'gpu': 'Confira sessão gráfica, resolução e aceleração; depois teste OpenGL/Vulkan suportados.',
    'armazenamento': 'Confira SMART em modo de leitura, montagem por UUID e backup recuperável.',
    'rede': 'Teste conectividade e transferência; detecção não confirma acesso à rede.',
    'audio': 'Teste reprodução e gravação, volume e dispositivo selecionado.',
}

def ler(path):
    try:
        return path.read_text(errors='replace')[:65536].strip()
    except OSError:
        return ''

def driver(path):
    link = path/'driver'
    return link.resolve().name if link.is_symlink() else ''

def componente(categoria, localizacao, atributos, vinculo=''):
    return dict(categoria=categoria, localizacao=localizacao, atributos=atributos,
                detectado=True, driver=vinculo or None,
                driver_vinculado=bool(vinculo), teste_funcional='NÃO EXECUTADO')

def coletar(raiz=pathlib.Path('/')):
    """raiz permite fixtures; produção usa /, sem executar comandos privilegiados."""
    itens = []
    ausencias = []
    proc, sys = raiz/'proc', raiz/'sys'
    cpu = ler(proc/'cpuinfo')
    modelos = re.findall(r'^model name\s*:\s*(.+)$', cpu, re.M)
    if modelos:
        itens.append(componente('processador', 'sistema', dict(modelos=sorted(set(modelos)),
                                processadores_logicos=len(modelos))))
    else:
        ausencias.append('Modelo do processador indisponível.')
    memoria = re.search(r'^MemTotal:\s*(\d+)\s+kB', ler(proc/'meminfo'), re.M)
    if memoria:
        itens.append(componente('memoria', 'sistema', dict(total_kib=int(memoria[1]))))
    else:
        ausencias.append('Capacidade de memória indisponível.')
    dmi = sys/'class/dmi/id'
    placa = {k: ler(dmi/v) for k,v in [('fabricante','board_vendor'),('modelo','board_name'),
                                    ('versao','board_version')] if ler(dmi/v)}
    if placa:
        itens.append(componente('placa_mae', 'sistema', placa))
    else:
        ausencias.append('Identificação da placa-mãe indisponível sem acesso adicional.')
    firmware = {'modo': 'UEFI' if (sys/'firmware/efi').is_dir() else 'Legacy',
                'fabricante': ler(dmi/'bios_vendor'), 'versao': ler(dmi/'bios_version')}
    if sys.is_dir():
        itens.append(componente('firmware','sistema',firmware))
    else:
        ausencias.append('Firmware não determinado: /sys indisponível.')
    classes = {'03':'gpu', '02':'rede', '04':'audio', '01':'controlador_armazenamento'}
    for path in sorted((sys/'bus/pci/devices').glob('*')):
        classe = ler(path/'class').removeprefix('0x')[:2]
        attrs = {k: ler(path/k) for k in ('vendor','device','subsystem_vendor','subsystem_device','class')}
        itens.append(componente(classes.get(classe,'pci'), path.name, attrs, driver(path)))
    for path in sorted((sys/'bus/usb/devices').glob('*')):
        if not ler(path/'idVendor'):
            continue
        attrs = {k:ler(path/k) for k in ('idVendor','idProduct','manufacturer','product')}
        # Interfaces USB podem conter o vínculo de driver em vez do dispositivo pai.
        vinculos = sorted({driver(p) for p in path.glob(path.name+':*') if driver(p)})
        itens.append(componente('usb',path.name,attrs,driver(path) or ', '.join(vinculos)))
    for path in sorted((sys/'block').glob('*')):
        if path.name.startswith(('loop','ram','zram','dm-')):
            continue
        # O nome atual é evidência de localização, nunca um caminho persistente de boot.
        attrs = {'modelo':ler(path/'device/model'), 'fabricante':ler(path/'device/vendor'),
                 'setores_512_bytes':ler(path/'size'), 'removivel':ler(path/'removable')}
        itens.append(componente('armazenamento',path.name,attrs,driver(path/'device')))
    for path in sorted((sys/'class/net').glob('*')):
        if path.name == 'lo':
            continue
        itens.append(componente('interface_rede',path.name,{'tipo':ler(path/'type')},driver(path/'device')))
    for bus in ('pci','usb'):
        if not (sys/f'bus/{bus}/devices').is_dir():
            ausencias.append(f'Barramento {bus.upper()} indisponível.')
    return dict(schema=SCHEMA, criado_em=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                componentes=itens, limitacoes=ausencias+[
                    'Memória total utilizável, sem identificar módulos DIMM.',
                    'Localizações podem mudar após troca de placa ou porta; substituição é uma hipótese.',
                    'Driver vinculado é evidência do kernel, não comprovação de funcionamento.',
                    'Nenhum teste funcional foi executado. Sem inferência automática de incompatibilidade.'])

def validar(dados):
    if dados.get('schema') != SCHEMA or not isinstance(dados.get('componentes'),list):
        raise ValueError('Formato de inventário incompatível.')
    vistos = set()
    for item in dados['componentes']:
        chave = (item.get('categoria'),item.get('localizacao'))
        if not all(isinstance(v,str) and v for v in chave) or chave in vistos:
            raise ValueError('Componente duplicado ou identificação inválida.')
        if not isinstance(item.get('atributos'),dict):
            raise ValueError('Atributos inválidos.')
        vistos.add(chave)
    return dados

def carregar(path):
    if path.stat().st_size > 5*1024*1024:
        raise ValueError('Inventário excede 5 MiB.')
    return validar(json.loads(path.read_text(encoding='utf-8')))

def comparar(antes, depois):
    a = {(i['categoria'],i['localizacao']):i for i in validar(antes)['componentes']}
    b = {(i['categoria'],i['localizacao']):i for i in validar(depois)['componentes']}
    resultado = dict(adicionados=[], removidos=[], possiveis_substituicoes=[], drivers_alterados=[])
    for chave in sorted(a.keys() | b.keys()):
        if chave not in a:
            resultado['adicionados'].append(b[chave])
        elif chave not in b:
            resultado['removidos'].append(a[chave])
        else:
            par = dict(anterior=a[chave], atual=b[chave])
            if a[chave]['atributos'] != b[chave]['atributos']:
                resultado['possiveis_substituicoes'].append(par)
            if a[chave].get('driver') != b[chave].get('driver'):
                resultado['drivers_alterados'].append(par)
    resultado['aviso'] = 'Alteração de localização ou dados ausentes pode parecer troca. Confirme fisicamente; testes funcionais NÃO EXECUTADOS.'
    return resultado

def texto(dados):
    linhas = ['Diagnóstico de Upgrade FÊNIX', 'Dados locais; não enviados automaticamente.']
    if 'componentes' in dados:
        for i in dados['componentes']:
            linhas.append(f"\n{i['categoria']} — {i['localizacao']}: {json.dumps(i['atributos'],ensure_ascii=False)}")
            linhas.append(f"Detectado: sim | Driver vinculado: {i.get('driver') or 'não identificado'} | Teste funcional: NÃO EXECUTADO")
            if i['categoria'] in SUGESTOES:
                linhas.append('Verificação sugerida: '+SUGESTOES[i['categoria']])
        linhas.extend(dados.get('limitacoes',[]))
    else:
        for chave in ('adicionados','removidos','possiveis_substituicoes','drivers_alterados'):
            linhas.append('\n'+chave.replace('_',' ').capitalize()+':')
            linhas.extend(json.dumps(i,ensure_ascii=False) for i in dados[chave])
            if not dados[chave]: linhas.append('Nenhum registrado.')
        linhas.append(dados['aviso'])
    return '\n'.join(linhas)+'\n'

def salvar(dados, pasta):
    if pasta.is_symlink(): raise ValueError('Pasta de inventários não pode ser link simbólico.')
    pasta.mkdir(parents=True, exist_ok=True, mode=0o700)
    path = pasta/(datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S')+'-'+uuid.uuid4().hex[:8]+'.json')
    with open(path,'x',encoding='utf-8',opener=lambda p,f:os.open(p,f,0o600)) as stream:
        json.dump(dados,stream,ensure_ascii=False,indent=2)
    return path

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--comparar',nargs=2,type=pathlib.Path,metavar=('ANTERIOR','ATUAL'))
    parser.add_argument('--pasta',type=pathlib.Path,default=pathlib.Path(os.environ.get('XDG_STATE_HOME',str(pathlib.Path.home()/'.local/state')))/'fenix/inventarios')
    parser.add_argument('--gui',action='store_true',help='Exibir inventário e comparação com o último registro em janela local.')
    args = parser.parse_args()
    try:
        if args.comparar:
            relatorio = texto(comparar(*(carregar(p) for p in args.comparar)))
        else:
            if os.name != 'posix' or not pathlib.Path('/sys').is_dir():
                raise ValueError('Coleta real requer Linux com /proc e /sys; comparação funciona offline.')
            anteriores = sorted(args.pasta.glob('*.json')) if args.pasta.is_dir() else []
            dados = coletar()
            anterior = carregar(anteriores[-1]) if anteriores else None
            path = salvar(dados,args.pasta)
            relatorio = texto(dados)+'\nInventário salvo em: '+str(path)+'\n'
            if anterior: relatorio += texto(comparar(anterior,dados))
        if args.gui and os.environ.get('DISPLAY') and shutil.which('yad'):
            with tempfile.NamedTemporaryFile('w',encoding='utf-8',suffix='.txt') as stream:
                stream.write(relatorio); stream.flush()
                subprocess.run(['yad','--text-info','--title=Diagnóstico de Upgrade FÊNIX',
                                '--width=850','--height=600','--button=Fechar:0','--filename='+stream.name],check=False)
        else:
            print(relatorio)
    except (OSError,ValueError,TypeError,KeyError) as erro:
        parser.exit(1,'FALHOU: '+str(erro)+'\n')

if __name__ == '__main__': main()
