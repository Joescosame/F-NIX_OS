# Correção da desmontagem

A [execução com diagnóstico](https://github.com/Joescosame/F-NIX_OS/actions/runs/43995292017) comprovou uma submontagem `efivarfs` em `rootfs/sys/firmware/efi/efivars`, abaixo de `sysfs`. O script anterior tentava desmontar somente `/sys`, resultando em EBUSY. O log antigo não continha essa árvore.

A limpeza agora registra findmnt/fuser/processos e usa desmontagem recursiva normal, filhos antes do pai, dentro do namespace privado. Não usa lazy, force nem encerra processos. Uma montagem realmente ocupada continua bloqueando a construção. O teste Linux cria montagens aninhadas e um processo com diretório ocupado, verificando ambos os comportamentos.

O diagnóstico revelou ainda `fatal library error, lookup self` em ps: havia namespace PID novo com `/proc` antigo. `unshare --mount-proc` monta proc para o namespace correto; falhas de ferramentas de diagnóstico não impedem a tentativa de limpeza.

Validação anterior da regressão: [21 testes, 19 aprovados e 2 exclusivos de Windows ignorados](https://github.com/Joescosame/F-NIX_OS/actions/runs/43995134316). A instalação completa e a homologação física continuam pendentes.
