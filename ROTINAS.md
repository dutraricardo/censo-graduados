# ROTINAS — censo-graduados

Muda quando a forma de trabalhar muda. Onde o projeto está: `ESTADO.md`.

## Abrir e encerrar

Skills do kit da estação: **`/abrir`** ao começar e **`/encerrar`** ao
terminar. Todo trabalho vai por branch e PR: o kit nega ao Claude Code o push
ao `main`, e o merge só acontece com a aprovação do Ricardo.

## Antes de encerrar, se algum número mudou

1. `Rscript R/graduados_censo.R`.
2. Relatório novo e datado em `reports/` (nunca editar o antigo).
3. Reescrever `ESTADO.md`.
4. `/encerrar`: commit no branch, PR, CI e merge com o "sim" do Ricardo.
