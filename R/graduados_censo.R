# Pessoas com ensino superior completo nos Censos Demográficos do IBGE
# (1960, 1970, 1980, 1991, 2000, 2010 e 2022), via pacote censobr, por:
# condição na força de trabalho, posição na ocupação, setor de atividade e
# área de formação.
#
# Uso, a partir da raiz do projeto:
#   Rscript R/graduados_censo.R [pasta_cache_censobr]
#
# Saídas em resultados/: um CSV por tabela, o cubo completo e um .xlsx com
# todas as tabelas. Contagens são pessoas (soma dos pesos amostrais); n_amostra
# é o número de registros por trás de cada célula.

# rótulos com acento: no Windows o R >= 4.2 já é UTF-8; no Linux/Codespaces, não
if (.Platform$OS.type != "windows") invisible(Sys.setlocale("LC_CTYPE", "C.UTF-8"))

suppressPackageStartupMessages({
  library(censobr)
  library(dplyr)
  library(tidyr)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 1) censobr::set_censobr_cache_dir(args[1])

source("R/mapeamentos.R")
source("R/censos.R")

dir.create("resultados", showWarnings = FALSE)

rotulos <- read.csv("dados_aux/rotulos_dicionario.csv", fileEncoding = "UTF-8")
VAR_CURSO <- c("1960" = "V214", "1970" = "V039", "1980" = "V525", "1991" = "V0329",
               "2000" = "V4354", "2010" = "V6352")
VAR_ATIV <- c("1960" = "V223B", "1970" = "V045", "1980" = "V532", "1991" = "V0347",
              "2000" = "V4462", "2010" = "V6471")
# 1980: o dicionário do censobr traz rótulos-exemplo para V525 (ex.: 85 =
# "diplomacia"); a grade de códigos é a mesma de 1991, cujos rótulos são usados
rotulo_de <- function(ano, var, codigo) {
  r <- rotulos[rotulos$ano == ano & rotulos$variavel == var, ]
  unname(setNames(r$rotulo, r$codigo)[as.character(codigo)])
}

NAO_OCUPADO <- "Não se aplica (não ocupado)"
NAO_DISP_22 <- "Não disponível no microdado público de 2022"

base <- bind_rows(lapply(names(CENSOS), function(ano) {
  message("Censo ", ano, "...")
  d <- CENSOS[[ano]]()
  d$ano <- as.integer(ano)
  ano_rot <- if (ano == "1980") "1991" else ano
  var_curso <- if (ano == "1980") "V0329" else VAR_CURSO[ano]
  if (ano != "2022") {
    d$curso <- ifelse(is.na(d$curso_cod), "Curso não informado",
                      paste0(d$curso_cod, " - ",
                             coalesce(rotulo_de(ano_rot, var_curso, d$curso_cod), "sem rótulo no dicionário")))
    d$atividade <- ifelse(is.na(d$ativ_cod), NA,
                          paste0(d$ativ_cod, " - ",
                                 coalesce(rotulo_de(ano, VAR_ATIV[ano], d$ativ_cod), "sem rótulo no dicionário")))
  } else {
    d$curso <- NAO_DISP_22
    d$atividade <- NA
  }
  message("  ", nrow(d), " registros, ", format(round(sum(d$peso)), big.mark = ".", decimal.mark = ","), " pessoas")
  d
}))

base <- base |>
  mutate(
    condicao = unname(CONDICOES[cond]),
    posicao = ifelse(is.na(pos_h), NAO_OCUPADO, unname(POSICOES[pos_h])),
    posicao_detalhada = ifelse(is.na(pos_det), NAO_OCUPADO, pos_det),
    setor = case_when(is.na(setor_h) ~ NAO_OCUPADO,
                      setor_h == "NA22" ~ NAO_DISP_22,
                      TRUE ~ unname(SETORES[setor_h])),
    atividade = case_when(cond != "C1" ~ NAO_OCUPADO,
                          ano == 2022 ~ NAO_DISP_22,
                          TRUE ~ atividade),
    area = ifelse(area_h == "NA22", NAO_DISP_22, unname(AREAS[area_h]))
  )

tabela <- function(df, ...) {
  df |>
    group_by(ano, ...) |>
    summarise(pessoas = round(sum(peso)), n_amostra = n(), .groups = "drop_last") |>
    mutate(pct = round(100 * pessoas / sum(pessoas), 2)) |>
    ungroup() |>
    arrange(ano, ...)
}

larga <- function(t, linha) {
  t |>
    select(all_of(linha), ano, pessoas) |>
    pivot_wider(names_from = ano, values_from = pessoas, values_fill = 0)
}

ocup <- filter(base, cond == "C1")

# taxa de participação e de desocupação entre os graduados
indicadores <- base |>
  group_by(ano) |>
  summarise(
    graduados = round(sum(peso)),
    ocupados = round(sum(peso[cond == "C1"])),
    desocupados = round(sum(peso[cond == "C2"])),
    fora_da_forca = round(sum(peso[cond == "C3"])),
    nao_declarado = round(sum(peso[cond == "C9"])),
    n_amostra = n()
  ) |>
  mutate(
    taxa_participacao_pct = round(100 * (ocupados + desocupados) / (graduados - nao_declarado), 2),
    taxa_desocupacao_pct = round(100 * desocupados / (ocupados + desocupados), 2),
    nivel_ocupacao_pct = round(100 * ocupados / (graduados - nao_declarado), 2)
  )

tabs <- list(
  "01_indicadores" = indicadores,
  "02_condicao" = tabela(base, condicao),
  "03_posicao" = tabela(ocup, posicao),
  "04_posicao_detalhada" = tabela(ocup, posicao_detalhada),
  "05_setor" = tabela(ocup, setor),
  "06_area" = tabela(base, area),
  "07_area_condicao" = tabela(base, area, condicao),
  "08_area_posicao" = tabela(ocup, area, posicao),
  "09_area_setor" = tabela(ocup, area, setor),
  "10_curso_condicao" = tabela(base, curso, condicao),
  "11_atividade_detalhada" = tabela(ocup, atividade),
  "12_cubo" = tabela(base, condicao, posicao, posicao_detalhada, setor, area, curso)
)

for (n in names(tabs)) {
  readr::write_csv(tabs[[n]], file.path("resultados", paste0(n, ".csv")), na = "")
}

# no Excel, as tabelas de uma dimensão também em formato largo (anos nas colunas)
largas <- list(
  "L_condicao" = larga(tabs[["02_condicao"]], "condicao"),
  "L_posicao" = larga(tabs[["03_posicao"]], "posicao"),
  "L_setor" = larga(tabs[["05_setor"]], "setor"),
  "L_area" = larga(tabs[["06_area"]], "area")
)
writexl::write_xlsx(c(largas, tabs), "resultados/graduados_censo_1960_2022.xlsx")

message("Pronto: resultados/")
print(as.data.frame(indicadores))
