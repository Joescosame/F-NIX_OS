# Investigação do instalador e relógio

## Evidências observadas

A ISO local tem SHA-256 `45a835b5dddaf40e84d776549e0b19b3fbd49673b6cc6434ebddbfcd217df776`. O manifesto oficial baixado corresponde a esse hash. A assinatura GPG local nesta sessão está BLOQUEADA pela execução do binário GnuPG no sandbox Windows; o construtor exige verificação GPG real antes de modificar a base.

Extração de leitura com 7-Zip identificou Ubiquity `24.04.3+mint19`. O arquivo original foi preservado para regressão em `tests/fixtures/ubi-timezone.py`, sob GPL-2.0-or-later. Em `PageGtk.geoname_cb`, `_bytes` inicia como None; uma falha/cancelamento de `send_and_read_finish` pode deixá-lo vazio, enquanto o status da mensagem ainda pode permitir `get_data()`. O unittest reproduz `AttributeError` neste caminho usando doubles de rede.

Isso comprova um defeito do callback, **não comprova que foi a única causa do incidente físico**. A espera de hora de servidor é outro caminho, ligado a clock-setup/NTP. Não possuímos logs completos nem reproduzimos a instalação que ficou durante a noite. SSD sem boot também exige verificar conclusão de cópia, particionamento MBR e instalação GRUB.

## Correções implementadas

`tools/patch-timezone.py` modifica somente o plugin da ISO extraída. Recusa layout desconhecido, conserva `.fenix-original`, valida AST e é idempotente. Valida resposta antes de ler bytes/JSON, conserva fallback local e impede que resposta antiga substitua consulta nova. Quando offline, não consulta GeoIP. Testes incluem cancelamento, None, HTTP falho, JSON inválido/incompleto, Unicode inválido e resultado válido.

`Instalar FÊNIX (modo offline)` aplica preseed `clock-setup/ntp=false`, fuso padrão America/Sao_Paulo editável e força caminho offline do plugin. Preserva o modo de execução gráfica usado pelo Mint, incluindo `WEBKIT_DISABLE_COMPOSITING_MODE=1`. Não seleciona disco e não inicia instalação desassistida. O instalador original permanece disponível para comparação.

Não desativamos serviço de horário no sistema instalado nem alteramos RTC/BIOS do computador. Verifique data da BIOS, pilha CMOS e hora da sessão; data incorreta pode causar erros TLS. Instale sem rede na primeira campanha e confira sincronização após login quando conectar.

## Fontes primárias

- [Verificação oficial Linux Mint](https://linuxmint-installation-guide.readthedocs.io/en/latest/verify.html): hash, assinatura e fingerprint.
- [Diretório oficial Mint 22.3](https://pub.linuxmint.io/stable/22.3/).
- [Plugin upstream Ubiquity](https://github.com/linuxmint/ubiquity/blob/master/ubiquity/plugins/ubi-timezone.py): código de consulta e preseed offline.

O teste decisivo continua BLOQUEADO: ISO FÊNIX → boot SeaBIOS → instalador offline → disco MBR → reinício sem ISO → login. Veja `QA.md`.
