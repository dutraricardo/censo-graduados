# censo-graduados — regras

Projeto de dados **públicos**: microdados dos Censos Demográficos do IBGE via
pacote `censobr`. Nenhum dado, credencial ou nome de sistema do ministério
entra aqui.

## Escopo

Contar pessoas com superior completo por condição na força de trabalho,
posição na ocupação, setor de atividade e área de formação, em todos os
censos que o `censobr` oferece com microdados de pessoas.

## Regras

- **Toda leitura passa pelo `censobr`** (`read_population`). Nada de baixar
  parquet por fora: o pacote fixa a versão dos dados (`v1.0.0` hoje).
- **Regra de cada censo mora em `R/censos.R`, classificação comum em
  `R/mapeamentos.R`.** Mudou uma regra, mudam o código e um relatório novo e
  datado em `reports/`.
- **O cache do censobr (~4 GB) nunca entra no git.** Fica no padrão do pacote
  ou na pasta passada ao script.
- **Resultados (`resultados/`) entram no git**: são agregados públicos e
  pequenos, e o diff mostra quando um número muda.
- 1980 usa os rótulos de curso de 1991 (mesma grade de códigos): o dicionário
  do censobr traz rótulos-exemplo para `V525` (85 = "diplomacia", que na
  verdade é "outros cursos superiores").
- Ao trazer o microdado controlado de 2022 (`censobr::import_microdata22()`),
  ele fica fora do repositório e só os agregados entram.

## Documentação

`ESTADO.md` (onde está e o que vem), `ROTINAS.md` (abrir e encerrar sessão),
`reports/` (provas datadas, nunca reescritas).
