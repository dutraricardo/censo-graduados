# censo-graduados

Pessoas com ensino superior completo nos Censos Demográficos do IBGE de 1960,
1970, 1980, 1991, 2000, 2010 e 2022 — todos os censos com microdados de
pessoas no pacote [censobr](https://ipeagit.github.io/censobr/) — por
condição na força de trabalho (ocupado, desocupado, fora da força), posição
na ocupação, setor de atividade e área de formação.

## Rodar

R ≥ 4.3 com `censobr`, `dplyr`, `tidyr`, `readr` e `writexl`:

```r
install.packages(c("censobr", "dplyr", "tidyr", "readr", "writexl"))
```

Da raiz do projeto:

```sh
Rscript R/graduados_censo.R            # cache padrão do censobr
Rscript R/graduados_censo.R D:/cache   # ou uma pasta de cache escolhida
```

A primeira execução baixa ~4 GB de parquet (um arquivo por censo); depois
roda em cerca de 2 minutos.

## Arquivos

| Caminho | O que é |
|---|---|
| `R/graduados_censo.R` | script principal: lê, classifica, tabula e grava |
| `R/censos.R` | regra de cada censo (quem é graduado, condição, posição) |
| `R/mapeamentos.R` | classificações harmonizadas de área, setor e posição |
| `dados_aux/rotulos_dicionario.csv` | rótulos de cursos e atividades, tirados dos dicionários do censobr |
| `resultados/*.csv` | uma tabela por arquivo (`ano`, dimensões, `pessoas`, `n_amostra`, `pct`) |
| `resultados/graduados_censo_1960_2022.xlsx` | todas as tabelas; abas `L_*` com os anos nas colunas |
| `reports/metodologia_20261027.md` | regras por ano, limites de comparação e os números |

`resultados/12_cubo.csv` cruza todas as dimensões (condição × posição ×
posição detalhada × setor × área × curso) e permite montar qualquer outra
tabela.

## Limites

O microdado público de 2022 não tem curso superior nem atividade; para 2022
só há condição e posição. Demais quebras de comparabilidade:
`reports/metodologia_20261027.md`.
