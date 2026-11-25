# ESTADO — censo-graduados

Atualizado em 2026-11-25.

## Onde está

Primeira versão completa: sete censos (1960–2022) lidos pelo `censobr` 1.0.0,
tabelas em `resultados/`, regras e números em
`reports/metodologia_20261027.md`. Os números não mudaram desde então.

Totais conferidos contra o SIDRA em 25/11: 1991 e 2010 batem exatamente;
2000 tem diferença explicada; 2022 difere 0,09%, ainda sem explicação; 1960 a
1980 não estão no SIDRA. Detalhe em `reports/conferencia_sidra_20261125.md`.

Kit da estação na versão 5 (25/11). O projeto está registrado na estação
(`ferramentas\repos.json` e `README.md` do `claude-estacao`).

## Ler, nesta ordem

1. `reports/metodologia_20261027.md` — regras por ano e o que não se compara.
2. `reports/conferencia_sidra_20261125.md` — o que bate com o IBGE e o que não.
3. `R/censos.R` e `R/mapeamentos.R` — onde as regras estão em código.

## Próximos passos

1. **Explicar a diferença de 2022 contra o SIDRA** (0,09% no total), em
   máquina com R: hipótese no `reports/conferencia_sidra_20261125.md`.

## Perguntas em aberto para o Ricardo

1. **2022 com área e setor** só sai do microdado controlado do IBGE
   (`censobr::import_microdata22()`). Vale pedir acesso? O SIDRA já publica o
   total de 2022 por área (tabelas 10063 a 10065), sem cruzar com ocupação.
2. A área de 2010 deve reclassificar as licenciaturas (código 145) pela
   disciplina, para comparar com 2000? (item 2 dos limites no relatório)
3. 1960 a 1980 só se conferem contra os volumes impressos do Censo. Vale o
   trabalho?
