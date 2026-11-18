---
name: abrir
description: Abre a sessão de trabalho neste repositório segundo a metodologia da estação (C:\Claude\docs\metodologia.md).
disable-model-invocation: true
---

# Abrir a sessão

Siga na ordem e pare para perguntar se algo não bater.

1. **Git.** `git status -sb` e `git fetch origin`. Diga o branch atual, se há
   arquivo alterado e se o branch principal está atrás do GitHub. Se estiver no
   principal, lembre que o trabalho vai num branch de tarefa (o push ao principal
   é bloqueado).
2. **Guarda.** Se existir `.githooks/`, confirme `git config --get core.hooksPath`
   = `.githooks` (o hook de abertura já tenta ativar).
3. **Estado.** Leia o `ESTADO.md` e siga a lista de leitura dele. Ela é a única.
4. **Resumo ao Ricardo**, em até cinco linhas: onde o projeto está, o próximo
   passo, o que está pendente com ele.
5. **Tarefa.** Se a tarefa do dia não tem issue, mostre o título e uma frase,
   sem nenhum valor individual de dado no texto, e crie você mesmo:
   `gh issue create --title "..." --body "..."`, depois
   `gh project item-add <N> --owner dutraricardo --url <url da issue>`
   (Project 1 = institucional, 2 = pessoal). Em seguida, o branch da tarefa,
   sempre a partir do principal em dia: `git switch <principal>`,
   `git pull --prune`, `git switch -c claude/<tema>-AAAAMMDD`. O Ricardo não
   precisa ir à web.

Nunca abra arquivo de dado real (`data/`, planilhas, bancos): o que o Claude lê
vai ao provedor. Para saber algo do dado, rode o script que imprime só agregado.
