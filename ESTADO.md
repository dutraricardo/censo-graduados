# ESTADO — censo-graduados

Atualizado em 2026-10-27.

## Onde está

Primeira versão completa: sete censos (1960–2022) lidos pelo `censobr` 1.0.0,
tabelas em `resultados/`, regras e números em
`reports/metodologia_20261027.md`.

## Ler, nesta ordem

1. `reports/metodologia_20261027.md` — regras por ano e o que não se compara.
2. `R/censos.R` e `R/mapeamentos.R` — onde as regras estão em código.

## Próximos passos

1. **Conferir totais contra o SIDRA** (graduados por ano e condição de
   atividade). Não foi feito: o SIDRA estava bloqueado na sessão de origem.
2. **2022 com área e setor**: só com o microdado controlado do IBGE, via
   `censobr::import_microdata22()`. Decidir se vale pedir acesso.
3. Decidir se a área de 2010 deve reclassificar as licenciaturas (código 145)
   pela disciplina, para comparar com 2000 (ver item 2 dos limites no relatório).
4. Registrar o projeto no `README.md` da raiz e no `sincronizar.ps1` do
   `claude-estacao`, depois de decidir se a pasta local é `institucional\` ou
   `pessoal\`.
