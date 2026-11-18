---
name: encerrar
description: Encerra a sessão de trabalho neste repositório segundo a metodologia da estação (C:\Claude\docs\metodologia.md).
disable-model-invocation: true
---

# Encerrar a sessão

Siga na ordem. Nada vai para o branch principal direto: só por PR, com merge
aprovado pelo Ricardo.

1. **Verificação.** Se o repositório tem código: `uv run ruff check .` e, havendo
   `tests/`, `uv run pytest -q`. **Mostre a saída** ao Ricardo; "passou" sem a
   saída não conta. Falhou: corrija ou diga o que falta, sem comitar por cima.
2. **`ESTADO.md`.** Reescreva: o que foi feito, onde o projeto está, o próximo
   passo, perguntas em aberto para o Ricardo e a lista de leitura. Estado se
   aponta, não se repete; relatório novo vai para `reports/<tema>_AAAAMMDD.md`.
3. **Commit** no branch da tarefa, mensagem em português, com as linhas de
   atribuição da sessão. Nunca `--no-verify`, nunca `git add -f`.
4. **Push** do branch (`git push -u origin <branch>`).
5. **PR** para o principal com `gh pr create`, citando a issue (`Closes #N`
   quando fechar: o GitHub só reconhece a palavra-chave em inglês). Texto sem
   valor individual de dado.
6. **CI e revisão.** `gh pr checks <N> --watch` até terminar; vermelho: corrija
   no branch e repita. Verde: `/code-review` no diff e mostre os achados.
7. **Resumo** em até cinco linhas: o que mudou, o link do PR, CI e revisão.
   Pergunte se pode fazer o merge.
8. **Merge, só com o "sim" do Ricardo:** `gh pr merge <N> --merge --delete-branch`.
   A guarda abre a janela de aprovação; quem aprova é ele (ADR 0012 da
   estação). Nunca `--admin`. Depois: `gh pr view <N> --json state` deve dizer
   `MERGED`; então `git switch <principal>` e `git pull --prune`, e confira que
   `git log -1` é o merge.
