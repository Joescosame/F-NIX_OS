> Documento histórico v0.2.2 preservado. Para o procedimento atual, siga COMECE_AQUI.md, BUILD.md, QA.md e NEWELLE_FASE2.md. As instruções antigas não autorizam executar módulos ou publicar resultados.

# 06 — Newelle com DeepSeek (fase 2, opcional)

**Status:** projeto de build, sem compilação/homologação no Mint 22.3 real. **A ISO base tem prioridade.**

## Fatos upstream consultados (16/11/2026)
- Repositório: https://github.com/qwersyk/Newelle
- Documentação Meson sem Flatpak: https://newelle.qsk.me/docs/Building-Newelle-without-Flatpak
- `install.sh` do repositório **chama flatpak-builder**. Não executá-lo neste projeto.
- `modules/requirements.txt` inclui Python (requests, expandvars, pillow, pyaudio,
  pydub, webrtcvad-wheels, openai, tiktoken, newspaper3k, mcp, lxml,
  lxml_html_clean, pylatexenc, matplotlib, markdownify, pysilero-vad) e opções
  pesadas para embeddings/RAG/voz local: model2vec, faiss-cpu, llama-index,
  speechrecognition, gtts, openwakeword etc. Também documenta VTE, PortAudio,
  WebKitGTK 6 e Git. **Não** fazemos `pip install -r` integral para uso DeepSeek.
- Meson da branch de consulta: `project('newelle',version:'1.6.1')`. Muda com upstream:
  o script registra o SHA local para reproduzir e aceita `NEWELLE_REF`.

## Uso somente em Mint já instalado e com internet
```bash
bash scripts/build-newelle.sh
bash scripts/install-newelle.sh
```
Build usa `meson setup builddir --prefix=/usr/local`, `meson compile`, `meson install`.
Recursos gráficos GTK4/WebKitGTK podem exigir versões mais recentes que Noble:
se o app não abrir, registrar erro e **não** substituir o Mint LTS por bibliotecas
experimentais. O prefixo `/usr/local` reduz colisões com pacotes Ubuntu.

## Configuração DeepSeek sem armazenar segredo no projeto
1. Criar chave em https://platform.deepseek.com/api_keys.
2. Abrir **Assistente IA (Newelle)** e selecionar provedor **DeepSeek**.
3. Colar chave no campo **API Key** somente na interface do aplicativo.
4. Selecionar `deepseek-flash` ou outro modelo atual listado pela plataforma.
5. Testar mensagem curta e conferir resposta, custos e rede.

O handler DeepSeek oficial está em `src/handlers/llm/deepseek_handler.py` e utiliza
`https://api.deepseek.com`; leia a documentação atual em
https://api-docs.deepseek.com/en/.

## Segurança e privacidade
- Newelle instalado sem sandbox Flatpak tem acesso normal do seu usuário.
- Inicialmente desativar autoexecução de comandos e restringir arquivos por pasta.
- Não compartilhar chave, conteúdos contábeis confidenciais ou dados pessoais.
- Reversão: `bash scripts/uninstall-newelle.sh` (não exclui dados pessoais).
- Dependências apt instaladas na fase 2 devem ser revisadas via
  `~/.local/state/fenix-newelle/packages-added.txt` antes de remoção.
- Logs: `~/TestesPC/logs/build-newelle.log`.

## QA específico
Ver `docs/03_QA.md`: iniciar GUI Xfce, menu/Hub/Plank, API, permissões,
RAM com 8 GB, reversão e ausência de Flatpak/Snap.
