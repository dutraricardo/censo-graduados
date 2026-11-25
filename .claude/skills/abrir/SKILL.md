---
name: abrir
description: Abre a sessão de trabalho neste repositório segundo a metodologia da estação (C:\Claude\docs\metodologia.md).
disable-model-invocation: true
---

# Abrir a sessão

Siga na ordem e pare para perguntar se algo não bater. Todo comando git leva
`-C "<pasta completa do repositório>"` (`<repo>` abaixo): numa pasta que não é
repositório, o git responde pelo repositório da raiz da estação.

1. **Git.** `git -C <repo> status -sb` e `git -C <repo> fetch origin`. Diga o branch atual, se há
   arquivo alterado e se o branch principal está atrás do GitHub. Se estiver no
   principal, lembre que o trabalho vai num branch de tarefa (o push ao principal
   é bloqueado).
2. **Guarda.** Se existir `.githooks/`, confirme `git -C <repo> config --get core.hooksPath`
   = `.githooks` (o hook de abertura já tenta ativar).
3. **Estado.** Leia o `ESTADO.md` e siga a lista de leitura dele. Ela é a única.
   Se ele divergir do GitHub (cita issue já fechada, não cita issue aberta),
   vale o GitHub: diga ao Ricardo.
   **Kit.** O hook de abertura pode mostrar `(aviso) kit ... reaplicar quando o
   projeto for aberto`. Só `kit abaixo da versao minima` é pendência que vira
   issue.
   Nenhum dos dois abre sessão sozinho (ADR 0014 da estação). Se a sessão tem
   trabalho, a correção do `ESTADO.md` e a reaplicação do kit entram no PR
   dela. Se é só de conferência, ficam para a próxima sessão com trabalho.
4. **Resumo curto ao Ricardo**, só com: onde o projeto está, o próximo passo, o
   que está pendente com ele.
5. **Objetivo.** A sessão tem um objetivo só (ADR 0013 da estação); diga ao
   Ricardo qual é. Se não há trabalho (só conferência, nada a mudar), diga isso
   e pare: sem issue, sem branch.
   - **Cabe nesta sessão:** sem issue (ADR 0017 da estação). Vá direto ao branch.
   - **Atravessa mais de uma sessão:** precisa de issue. Se ainda não tem, mostre
     o título e uma frase, sem nenhum valor individual de dado no texto, e crie
     você mesmo: `gh issue create --title "..." --body-file <arquivo>` (o corpo
     vai num arquivo do scratchpad: texto no `--body` que cita um comando é
     julgado como comando pela guarda). O auto-add do Project a inclui; se não
     aparecer lá, `gh project item-add <N> --owner dutraricardo --url <url>`
     (Project 1 = institucional, 2 = pessoal).

   Branch sempre a partir do principal em dia: `git -C <repo> switch <principal>`,
   `git -C <repo> pull --prune`, `git -C <repo> switch -c claude/<tema>-AAAAMMDD`. O Ricardo não
   precisa ir à web.

A sessão termina em um PR (`/encerrar`), que fecha a issue quando houver. Se o
Ricardo pedir outro objetivo no meio, proponha `/clear` e nova sessão (com issue,
se ele não couber numa sessão).

Nunca abra arquivo de dado real (`data/`, planilhas, bancos): o que o Claude lê
vai ao provedor. Para saber algo do dado, rode o script que imprime só agregado.
