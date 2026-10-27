# ROTINAS — censo-graduados

## Abrir sessão — Claude Code

1. `git -C "<pasta do projeto>" pull`
2. Ler `ESTADO.md` e seguir a lista de leitura dele.

## Abrir sessão — Claude Cowork

Colar como primeira mensagem:

```
Projeto censo-graduados (repositório dutraricardo/censo-graduados): graduados
nos Censos do IBGE 1960-2022 via censobr, dados públicos. Leia ESTADO.md e o
relatório que ele indica em reports/. Seu papel: leitura crítica e fonte
externa (IBGE, SIDRA, classificações); não implemente sem pedido explícito.
```

## Encerrar sessão

1. Se algum número mudou: `Rscript R/graduados_censo.R` e relatório novo e
   datado em `reports/` (nunca editar o antigo).
2. Reescrever `ESTADO.md`.
3. Commit e push.
