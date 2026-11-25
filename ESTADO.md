# ESTADO — censo-graduados

Atualizado em 2026-11-25.

## Onde está

Primeira versão completa: sete censos (1960–2022) lidos pelo `censobr` 1.0.0,
tabelas em `resultados/`, regras e números em
`reports/metodologia_20261027.md`. Os números não mudaram desde então.

Kit da estação na versão 5 (25/11). O projeto está registrado na estação (`ferramentas\repos.json` e `README.md`
do `claude-estacao`), em `institucional\`, e o `sincronizar.ps1` já o confere.

## Ler, nesta ordem

1. `reports/metodologia_20261027.md` — regras por ano e o que não se compara.
2. `R/censos.R` e `R/mapeamentos.R` — onde as regras estão em código.

## Próximos passos

1. **Conferir totais contra o SIDRA** (graduados por ano e condição de
   atividade). Ainda não feito.

## Perguntas em aberto para o Ricardo

1. **2022 com área e setor** só sai do microdado controlado do IBGE
   (`censobr::import_microdata22()`). Vale pedir acesso?
2. A área de 2010 deve reclassificar as licenciaturas (código 145) pela
   disciplina, para comparar com 2000? (item 2 dos limites no relatório)
