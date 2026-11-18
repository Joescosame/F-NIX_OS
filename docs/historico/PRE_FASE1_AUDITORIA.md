> HISTÓRICO: relatório da etapa anterior, não representa o estado atual. Veja RESULTADO_BOOT_LIVE.md e FASE1_RESULTADOS.md.

# Auditoria e integração ao repositório oficial

## Escopo da etapa

Origem exclusiva: [Joescosame/F-NIX_OS](https://github.com/Joescosame/F-NIX_OS), pública conforme decisão expressa do usuário. A integração confirmou permissão administrativa. A `main` remota inicial continha somente o README; seu conteúdo foi preservado em `origem-github/README.md`. Nenhum arquivo remoto adicional foi descartado.

Os commits locais v0.3.0 (`d6da947`, `82d1148`, `1c8e0d7`) estão preservados em `archive/local-v0.3.0` no notebook. A branch `codex/legacy-iso-integration` reúne a integração e as correções. O push HTTPS direto está bloqueado pelo auxiliar de credenciais no sandbox Windows; a publicação pela API conectada pode gerar novos IDs, preservando os arquivos e registrando a origem das versões. Não configurar tokens em arquivos, URLs ou logs para contornar esse limite.

## Achados e correções

| Achado | Correção | Validação |
|---|---|---|
| Helper antigo podia criar outro repositório e exigia privado | Destino fixo F-NIX_OS, sem criação e sem mudança de visibilidade; Release usa o mesmo destino | Revisão de código, parser PowerShell e conferência de origin |
| Chroot compartilhava `/dev` do host | tmpfs com caracteres essenciais, devpts próprio e namespace de processos | ShellCheck; execução Linux ainda NÃO EXECUTADA |
| Atualização da mídia dependia da comparação de tamanho/data do xorriso | Reimportação explícita da árvore com `-map`, seguida de replay do boot | Revisão contra manual xorriso; build ainda NÃO EXECUTADO |
| Verificador aceitava entrada BIOS desabilitada e comparava poucos atributos | Exige BIOS habilitada, MBR e compara atributos El Torito adicionais | Regressão com relatórios sintéticos; não equivale a boot |
| Build podia tentar upload grande sem checar franquia | Upload desligado por padrão e retenção opcional de um dia | Teste do workflow e gatilho manual |
| Runner padrão pode não ter espaço | Limpeza limitada de SDKs em VM efêmera, seguida de preflight obrigatório | ShellCheck; guard fora do runner tem teste Linux |
| Documentação e helpers ainda apontavam ao destino anterior | Guias atuais apontam ao único repositório oficial; resultados anteriores identificados como históricos | Busca de referências e revisão |

Newelle permanece exclusivamente opcional na fase 2; não entra no build. ISO original, discos virtuais, chaves, credenciais e relatórios pessoais continuam fora do Git. As evidências públicas de testes contêm apenas resultados técnicos, sem caminhos pessoais ou dados de sensores do notebook.

## Testes e limite da conclusão

Executar `./tools/lint.sh` em Ubuntu 24.04. Nesta etapa Windows, a evidência atual fica em `tests/evidence/etapa-oficial/`: testes Python, validação YAML/desktop/SVG, ShellCheck, parser e reconstrução real em PowerShell 5.1. Os testes que precisam de Linux são explicitamente pulados. Não foram executados Actions, construção squashfs/chroot, boot SeaBIOS, instalação ou reboot de disco.

A assinatura GPG e o build seguem obrigatórios no Linux. O erro GeoIP possui regressão unitária, mas o travamento de NTP e a instalação completa continuam sem homologação. O objetivo continua sendo: construir → iniciar em Legacy → instalar offline em MBR → reiniciar sem ISO → login Xfce/Hub → validar H55 físico.

## Primeira ISO

Após esta integração estar na `main`, disparar manualmente primeiro **Validar fontes**, depois **Construir ISO não homologada** com runner padrão. Deixar upload desligado evita presumir armazenamento gratuito; para obter arquivo persistente, usar VM Linux própria com espaço ou habilitar upload somente após conferir a franquia. Se faltar disco, memória, dependências ou assinatura, o resultado é BLOQUEADO/FALHOU, nunca uma ISO aprovada.

O teste gráfico de instalação ainda requer operador na VM. Nenhuma Release estável é autorizada pela mera publicação do código.
