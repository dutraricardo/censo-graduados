---
name: encerrar
description: Encerra a sessão de trabalho neste repositório segundo a metodologia da estação (C:\Claude\docs\metodologia.md).
disable-model-invocation: true
---

# Encerrar a sessão

Siga na ordem. Nada vai para o branch principal direto: só por PR, com merge
aprovado pelo Ricardo. Todo comando git leva `-C "<pasta completa do
repositório>"` (`<repo>` abaixo): numa pasta que não é repositório, o git
responde pelo repositório da raiz da estação.

A sessão termina em **um PR** que leva o `ESTADO.md` (se o estado mudou) e
fecha a issue do objetivo, quando houver: issue só existe para trabalho que
atravessa sessões (ADR 0017 da estação). Correções do review entram nesse
mesmo PR (ADR 0013 da estação).
Quando não há PR (ADR 0014 da estação):

- **Nada mudou e nada se decidiu** (só conferência): não há o que fazer. Sem
  PR, sem comentário, sem `ESTADO.md`. Diga ao Ricardo em uma linha.
- **Diagnóstico ou decisão sem mudança de arquivo**: havendo issue, comente
  nela o resultado e o próximo passo (`gh issue comment <N> --body-file <arquivo>`,
  sem valor individual de dado); sem issue, resuma ao Ricardo e, se a decisão
  muda alguma coisa, registre-a no `ESTADO.md` ou numa ADR no próximo PR.

1. **Verificação.** Se o repositório tem código: `uv run ruff check .` e, havendo
   `tests/`, `uv run pytest -q`. **Mostre a saída** ao Ricardo; "passou" sem a
   saída não conta. Falhou: corrija ou diga o que falta, sem comitar por cima.
2. **`ESTADO.md`**, se o que ele diz mudou: onde o projeto está, o próximo
   passo, perguntas em aberto para o Ricardo e a lista de leitura. Só o estado
   **deste** repositório: o de outro se aponta pela issue de lá. Estado se
   aponta, não se repete; relatório novo vai para `reports/<tema>_AAAAMMDD.md`.
3. **Commit** no branch da tarefa, mensagem em português, com as linhas de
   atribuição da sessão. Nunca `--no-verify`, nunca `git add -f`.
4. **Push** do branch (`git -C <repo> push -u origin <branch>`).
5. **PR** para o principal com `gh pr create --body-file <arquivo>` (corpo num
   arquivo do scratchpad), citando a issue se houver (`Closes #N` quando
   fechar: o GitHub só reconhece a palavra-chave em inglês). Texto sem valor
   individual de dado.
6. **CI e revisão.** `gh pr checks <N> --watch` até terminar; vermelho: corrija
   no branch e repita. Verde: `/code-review` no diff e mostre os achados, só se
   o projeto é do tipo `prototipo_app` no `repos.json` da estação (ADR 0017); nos
   demais, o CI verde basta.
   - Arquivos copiados pelo `kit aplicar` (`.claude/hooks/`, `.claude/skills/`
     do kit, `.claude/settings.json`, `.claude/kit-versao`, `ci.yml`) ficam
     **fora** do review: foram revisados no PR da estação que os mudou.
   - Achado num arquivo do kit não se corrige aqui (o próximo `kit aplicar`
     desfaz). Se deixa sair dado ou apaga/publica no GitHub: issue na estação.
     Push ao principal o GitHub já recusa (ruleset, ADR 0016 da estação): não
     vira issue. Qualquer outro: um comentário na issue de casos
     de borda da estação (`gh issue comment 60 -R dutraricardo/claude-estacao`),
     sem sessão própria.
7. **Resumo curto**, só com: o que mudou, o link do PR, CI e revisão.
   Pergunte se pode fazer o merge.
8. **Merge, só com o "sim" do Ricardo:** `gh pr merge <N> --merge --delete-branch`.
   A guarda abre a janela de aprovação; quem aprova é ele (ADR 0012 da
   estação). Nunca `--admin`. Depois: `gh pr view <N> --json state` deve dizer
   `MERGED`; então `git -C <repo> switch <principal>` e `git -C <repo> pull --prune`,
   e confira que `git -C <repo> log -1` é o merge.
