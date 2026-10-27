# Leitura de cada censo pelo censobr e regra, ano a ano, de:
#   - quem tem superior completo (graduação concluída);
#   - condição na força de trabalho (ocupado / desocupado / fora);
#   - posição na ocupação, atividade e curso concluído.
#
# Cada função devolve um data.frame com uma linha por pessoa graduada:
#   peso, cond, pos_h, pos_det, setor_h, ativ_cod, area_h, curso_cod

ler <- function(ano, colunas) {
  censobr::read_population(year = ano, columns = colunas, showProgress = FALSE)
}

# posição, setor e atividade só valem para ocupados
so_ocupados <- function(df) {
  nao <- df$cond != "C1"
  df$pos_h[nao] <- NA
  df$pos_det[nao] <- NA
  df$setor_h[nao] <- NA
  df$ativ_cod[nao] <- NA
  df
}

rot <- function(codigos, rotulos) unname(rotulos[as.character(codigos)])

# ------------------------------------------------------------------ 1960 ---
# Superior completo: V214 (curso completo) entre 50 e 79, cursos de nível
# superior. Trabalho: V220 (atividade não econômica) e V223 (ocupação na
# última semana, para quem trabalhou no ano anterior).
censo_1960 <- function() {
  d <- ler(1960, c("V214", "V220", "V223", "V223B", "V224", "censobr_weight")) |>
    dplyr::filter(V214 >= 50, V214 <= 79) |>
    dplyr::collect()
  cond <- dplyr::case_when(
    d$V223 == 4 ~ "C2",
    d$V223 %in% c(2, 3, 5) ~ "C1",
    d$V220 %in% c(0, 1, 4:9) ~ "C3",
    TRUE ~ "C9"
  )
  pos <- c("5" = "P1", "6" = "P1", "7" = "P2", "8" = "P2", "9" = "P3", "0" = "P4", "1" = "P9")
  det <- c("5" = "Empregado público", "6" = "Empregado particular",
           "7" = "Conta própria", "8" = "Parceiro ou meeiro", "9" = "Empregador",
           "0" = "Membro da família (não remunerado)", "1" = "Ignorado")
  so_ocupados(data.frame(
    peso = d$censobr_weight, cond = cond,
    pos_h = dplyr::coalesce(rot(d$V224, pos), "P9"),
    pos_det = dplyr::coalesce(rot(d$V224, det), "Ignorado"),
    setor_h = setor_1960(d$V223B), ativ_cod = d$V223B,
    area_h = area_1960(d$V214), curso_cod = d$V214
  ))
}

# ------------------------------------------------------------------ 1970 ---
# Superior completo: V039 (espécie de curso concluído) entre 70 e 97 (todos
# com V038 = 4, último grau concluído superior). Trabalho: V043 (situação
# principal) e V047 (o que fazia na semana de 25 a 31/08/1970).
censo_1970 <- function() {
  d <- ler(1970, c("V039", "V043", "V045", "V046", "V047", "V054")) |>
    dplyr::filter(V039 >= 70, V039 <= 97) |>
    dplyr::collect()
  cond <- dplyr::case_when(
    d$V043 %in% 0:6 ~ "C3",
    d$V043 == 7 & d$V047 %in% 1:3 ~ "C1",
    d$V043 == 7 & d$V047 %in% 4:5 ~ "C2",
    TRUE ~ "C9"
  )
  pos <- c("1" = "P1", "2" = "P1", "3" = "P2", "4" = "P2", "5" = "P3", "6" = "P4", "0" = "P9")
  det <- c("1" = "Empregado público", "2" = "Empregado particular",
           "3" = "Conta própria ou autônomo", "4" = "Parceiro ou meeiro",
           "5" = "Empregador", "6" = "Não remunerado", "0" = "Sem declaração")
  so_ocupados(data.frame(
    peso = d$V054, cond = cond,
    pos_h = dplyr::coalesce(rot(d$V046, pos), "P9"),
    pos_det = dplyr::coalesce(rot(d$V046, det), "Sem declaração"),
    setor_h = setor_1970(d$V045), ativ_cod = d$V045,
    area_h = area_1970(d$V039), curso_cod = d$V039
  ))
}

# ------------------------------------------------------------------ 1980 ---
# Superior completo: V525 (tipo do último curso concluído) entre 43 e 96, ou
# último grau concluído mestrado/doutorado (V524 = 8), ou cursando
# mestrado/doutorado (V522 = 8). V524 = 7 sozinho NÃO basta: inclui quem
# concluiu só uma série do superior. Trabalho: V528 (trabalhou nos últimos
# 12 meses), V541 (o que fazia na última semana) e V529 (para quem não
# trabalhou no ano).
censo_1980 <- function() {
  d <- ler(1980, c("V522", "V524", "V525", "V528", "V529", "V532", "V533", "V541", "V604")) |>
    dplyr::filter((V525 >= 43 & V525 <= 96) | V524 == 8 | V522 == 8) |>
    dplyr::collect()
  cond <- dplyr::case_when(
    d$V528 %in% c(1, 5) & d$V541 %in% 1:3 ~ "C1",
    d$V541 == 4 ~ "C2",
    d$V528 == 3 & d$V529 %in% 1:2 ~ "C2",
    d$V528 %in% c(1, 5) & d$V541 %in% 5:6 ~ "C3",
    d$V528 == 3 & d$V529 %in% 3:9 ~ "C3",
    TRUE ~ "C9"
  )
  pos <- c("0" = "P4", "1" = "P1", "2" = "P1", "3" = "P1", "4" = "P3", "5" = "P2",
           "6" = "P1", "7" = "P3", "8" = "P2", "9" = "P9")
  det <- c("0" = "Sem remuneração", "1" = "Trabalhador agrícola volante com intermediário",
           "2" = "Trabalhador agrícola volante sem intermediário",
           "3" = "Parceiro ou meeiro empregado", "4" = "Parceiro ou meeiro empregador",
           "5" = "Parceiro ou meeiro conta própria", "6" = "Empregado",
           "7" = "Empregador", "8" = "Conta própria", "9" = "Sem declaração")
  curso <- ifelse(d$V525 >= 43 & d$V525 <= 96, d$V525, NA)
  so_ocupados(data.frame(
    peso = d$V604, cond = cond,
    pos_h = dplyr::coalesce(rot(d$V533, pos), "P9"),
    pos_det = dplyr::coalesce(rot(d$V533, det), "Sem declaração"),
    setor_h = setor_1980_1991(d$V532), ativ_cod = d$V532,
    area_h = area_1980_1991(curso), curso_cod = curso
  ))
}

# ------------------------------------------------------------------ 1991 ---
# Superior completo: V0329 (curso concluído) entre 43 e 97, ou último grau
# concluído mestrado/doutorado (V0328 = 8), ou cursando mestrado/doutorado
# (V0326 = 6). Trabalho: período de referência de 12 meses. V0345 (trabalhou
# habitual ou eventualmente) e V0358 (condição de quem não trabalhou).
censo_1991 <- function() {
  d <- ler(1991, c("V0326", "V0328", "V0329", "V0345", "V0347", "V0349", "V0350",
                   "V0358", "V7301")) |>
    dplyr::filter((V0329 >= 43 & V0329 <= 97) | V0328 == 8 | V0326 == 6) |>
    dplyr::collect()
  cond <- dplyr::case_when(
    d$V0345 %in% 1:2 ~ "C1",
    d$V0358 %in% 1:2 ~ "C2",
    d$V0358 %in% c(0, 3:9) ~ "C3",
    TRUE ~ "C9"
  )
  pos <- c("1" = "P1", "2" = "P1", "3" = "P2", "4" = "P1", "5" = "P2", "6" = "P1",
           "7" = "P1", "8" = "P1", "9" = "P2", "10" = "P3", "11" = "P4")
  det <- c("1" = "Trabalhador agrícola volante", "2" = "Parceiro ou meeiro empregado",
           "3" = "Parceiro ou meeiro autônomo", "4" = "Trabalhador doméstico empregado",
           "5" = "Trabalhador doméstico autônomo", "6" = "Empregado do setor privado",
           "7" = "Empregado do setor público - servidor público",
           "8" = "Empregado do setor público - empresa estatal",
           "9" = "Autônomo ou conta própria", "10" = "Empregador", "11" = "Sem remuneração")
  carteira <- c("1" = " - com carteira", "2" = " - não sabe se tem carteira", "3" = " - sem carteira")
  empregado <- d$V0349 %in% c(1, 2, 4, 6, 7, 8)
  pos_det <- dplyr::coalesce(rot(d$V0349, det), "Sem declaração")
  pos_det[empregado] <- paste0(pos_det[empregado], dplyr::coalesce(rot(d$V0350[empregado], carteira), ""))
  curso <- ifelse(d$V0329 >= 43 & d$V0329 <= 97, d$V0329, NA)
  so_ocupados(data.frame(
    peso = d$V7301, cond = cond,
    pos_h = dplyr::coalesce(rot(d$V0349, pos), "P9"),
    pos_det = pos_det,
    setor_h = setor_1980_1991(d$V0347), ativ_cod = d$V0347,
    area_h = area_1980_1991(curso), curso_cod = curso
  ))
}

# ------------------------------------------------------------------ 2000 ---
# Superior completo: curso mais elevado graduação e concluído (V0432 = 7 e
# V0434 = 1), ou mestrado/doutorado (V0432 = 8), ou cursando mestrado ou
# doutorado (V0430 = 13; para estes o curso de graduação não foi perguntado).
# Trabalho: semana de 23 a 29/07/2000, com a regra de ocupação do IBGE
# (V0439 a V0443) e procura de trabalho (V0455).
censo_2000 <- function() {
  d <- ler(2000, c("V0430", "V0432", "V0434", "V4354", "V0439", "V0440", "V0441",
                   "V0442", "V0443", "V0447", "V0448", "V0455", "V4462", "P001")) |>
    dplyr::filter((V0432 == 7 & V0434 == 1) | V0432 == 8 | V0430 == 13) |>
    dplyr::collect()
  ocup <- (d$V0439 %in% 1) | (d$V0440 %in% 1) | (d$V0441 %in% 1) |
    (d$V0442 %in% 1) | (d$V0443 %in% 1)
  cond <- dplyr::case_when(
    ocup ~ "C1",
    d$V0455 == 1 ~ "C2",
    d$V0455 == 2 ~ "C3",
    TRUE ~ "C9"
  )
  pos <- c("1" = "P1", "2" = "P1", "3" = "P1", "4" = "P1", "5" = "P3", "6" = "P2",
           "7" = "P4", "8" = "P4", "9" = "P4")
  det <- c("1" = "Trabalhador doméstico com carteira", "2" = "Trabalhador doméstico sem carteira",
           "3" = "Empregado com carteira", "4" = "Empregado sem carteira",
           "5" = "Empregador", "6" = "Conta própria",
           "7" = "Aprendiz ou estagiário sem remuneração",
           "8" = "Não remunerado em ajuda a membro do domicílio",
           "9" = "Trabalhador na produção para o próprio consumo")
  pos_det <- dplyr::coalesce(rot(d$V0447, det), "Sem declaração")
  pos_det[d$V0447 %in% 4 & d$V0448 %in% 1] <- "Empregado sem carteira - militar ou estatutário (RJU)"
  so_ocupados(data.frame(
    peso = d$P001, cond = cond,
    pos_h = dplyr::coalesce(rot(d$V0447, pos), "P9"),
    pos_det = pos_det,
    setor_h = setor_cnae_dom1(d$V4462 %/% 1000), ativ_cod = d$V4462,
    area_h = area_ocde(d$V4354), curso_cod = d$V4354
  ))
}

# ------------------------------------------------------------------ 2010 ---
# Superior completo: V6400 = 4 (nível de instrução derivado pelo IBGE).
# Trabalho: semana de 25 a 31/07/2010, variáveis derivadas V6900/V6910/V6930.
censo_2010 <- function() {
  d <- ler(2010, c("V6400", "V6352", "V6900", "V6910", "V6930", "V6940", "V6471", "V0010")) |>
    dplyr::filter(V6400 == 4) |>
    dplyr::collect()
  cond <- dplyr::case_when(
    d$V6910 == 1 ~ "C1",
    d$V6910 == 2 ~ "C2",
    d$V6900 == 2 ~ "C3",
    TRUE ~ "C9"
  )
  pos <- c("1" = "P1", "2" = "P1", "3" = "P1", "4" = "P2", "5" = "P3", "6" = "P4", "7" = "P4")
  det <- c("1" = "Empregado com carteira", "2" = "Militar ou funcionário público estatutário",
           "3" = "Empregado sem carteira", "4" = "Conta própria", "5" = "Empregador",
           "6" = "Não remunerado", "7" = "Trabalhador na produção para o próprio consumo")
  pos_det <- dplyr::coalesce(rot(d$V6930, det), "Sem declaração")
  pos_det[d$V6940 %in% 1] <- "Trabalhador doméstico com carteira"
  pos_det[d$V6940 %in% 2] <- "Trabalhador doméstico sem carteira"
  so_ocupados(data.frame(
    peso = d$V0010, cond = cond,
    pos_h = dplyr::coalesce(rot(d$V6930, pos), "P9"),
    pos_det = pos_det,
    setor_h = setor_cnae_dom2(d$V6471 %/% 1000), ativ_cod = d$V6471,
    area_h = area_ocde(d$V6352), curso_cod = d$V6352
  ))
}

# ------------------------------------------------------------------ 2022 ---
# Microdado PÚBLICO (o controlado só existe no IBGE): não traz curso superior
# (P0750) nem atividade (P0980/P1030). Superior completo: P0760 = 7.
# Trabalho: semana de referência, pessoas de 14 anos ou mais (P0930/P0950).
censo_2022 <- function() {
  d <- suppressWarnings(ler(2022, c("P0760", "P0930", "P0950", "P1020", "P0110"))) |>
    dplyr::filter(P0760 == 7) |>
    dplyr::collect()
  cond <- dplyr::case_when(
    d$P0950 == 1 ~ "C1",
    d$P0950 == 0 ~ "C2",
    d$P0930 == 0 ~ "C3",
    TRUE ~ "C9"
  )
  pos <- c("1" = "P1", "2" = "P1", "3" = "P1", "4" = "P1", "5" = "P1", "6" = "P1",
           "7" = "P1", "8" = "P3", "9" = "P2", "10" = "P4")
  det <- c("1" = "Empregado no setor privado com carteira",
           "2" = "Empregado no setor privado sem carteira",
           "3" = "Trabalhador doméstico com carteira", "4" = "Trabalhador doméstico sem carteira",
           "5" = "Empregado no setor público com carteira",
           "6" = "Empregado no setor público sem carteira",
           "7" = "Militar e servidor estatutário", "8" = "Empregador", "9" = "Conta própria",
           "10" = "Trabalhador familiar auxiliar")
  p1020 <- as.integer(d$P1020)
  so_ocupados(data.frame(
    peso = d$P0110, cond = cond,
    pos_h = dplyr::coalesce(rot(p1020, pos), "P9"),
    pos_det = dplyr::coalesce(rot(p1020, det), "Sem declaração"),
    setor_h = "NA22", ativ_cod = NA_integer_,
    area_h = "NA22", curso_cod = NA_integer_
  ))
}

CENSOS <- list(
  "1960" = censo_1960, "1970" = censo_1970, "1980" = censo_1980, "1991" = censo_1991,
  "2000" = censo_2000, "2010" = censo_2010, "2022" = censo_2022
)
