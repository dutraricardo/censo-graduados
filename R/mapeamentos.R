# Classificações harmonizadas entre censos (1960-2022).
#
# Cada censo usa sua própria lista de cursos superiores, de atividades e de
# posição na ocupação. Aqui elas são levadas a três classificações comuns:
#
#   area_h   grandes áreas de formação no padrão OCDE/Eurostat que o IBGE usa
#            desde 2000 (1 Educação ... 8 Serviços, 0 não especificada);
#   setor_h  15 grupamentos de atividade, compatíveis com as seções da CNAE;
#   pos_h    5 grupos de posição na ocupação.
#
# Para os cursos de 1960-1991, a área foi atribuída curso a curso usando como
# ponte o Censo 2000, que codifica cada pessoa nas duas listas (V4355, a lista
# antiga, e V4354, a OCDE). Ver reports/ do projeto.

AREAS <- c(
  "1" = "Educação",
  "2" = "Humanidades e artes",
  "3" = "Ciências sociais, negócios e direito",
  "4" = "Ciências, matemática e computação",
  "5" = "Engenharia, produção e construção",
  "6" = "Agricultura e veterinária",
  "7" = "Saúde e bem-estar social",
  "8" = "Serviços (inclui militar e defesa)",
  "0" = "Área não especificada ou agregada"
)

SETORES <- c(
  "S01" = "Agropecuária, produção florestal e pesca",
  "S02" = "Indústrias extrativas",
  "S03" = "Indústrias de transformação",
  "S04" = "Eletricidade, gás, água, esgoto e limpeza urbana",
  "S05" = "Construção",
  "S06" = "Comércio e reparação de veículos",
  "S07" = "Transporte, armazenagem, correio e telecomunicações",
  "S08" = "Alojamento e alimentação",
  "S09" = "Informação, finanças, imobiliárias, serviços profissionais e administrativos",
  "S10" = "Administração pública, defesa e seguridade social",
  "S11" = "Educação",
  "S12" = "Saúde humana e serviços sociais",
  "S13" = "Serviços domésticos",
  "S14" = "Outros serviços (artes, associações, serviços pessoais, organismos internacionais)",
  "S99" = "Atividade mal definida ou não declarada"
)

POSICOES <- c(
  "P1" = "Empregado (inclui doméstico, servidor público e militar)",
  "P2" = "Conta própria (inclui parceiro autônomo)",
  "P3" = "Empregador",
  "P4" = "Não remunerado ou produção para o próprio consumo",
  "P9" = "Posição não declarada"
)

CONDICOES <- c(
  "C1" = "Ocupado",
  "C2" = "Desocupado (procurando trabalho)",
  "C3" = "Fora da força de trabalho",
  "C9" = "Condição não declarada"
)

# vetor nomeado -> função de lookup; código fora da tabela vira `padrao`
lookup <- function(tab, padrao) {
  function(x) {
    out <- unname(tab[as.character(x)])
    out[is.na(out)] <- padrao
    out
  }
}

faixas <- function(...) {
  # faixas(c(50, 54, "2"), c(60, 60, "7")) -> vetor nomeado código -> valor
  regras <- list(...)
  out <- character()
  for (r in regras) {
    cods <- seq(as.integer(r[1]), as.integer(r[2]))
    out[as.character(cods)] <- r[3]
  }
  out
}

# ---------------------------------------------------------------- área ----

area_1960 <- lookup(faixas(
  c(50, 50, "2"), # geografia e história (bacharelado e didática)
  c(51, 51, "4"), # história natural
  c(52, 52, "2"), # letras
  c(53, 53, "4"), # matemática, física, química e desenho
  c(54, 54, "0"), # outros: pedagogia, filosofia, ciências sociais, teologia
  c(57, 57, "2"), # belas artes
  c(60, 62, "7"), # medicina, farmácia, odontologia
  c(63, 63, "6"), # veterinária
  c(64, 66, "5"), # engenharia, arquitetura, química industrial
  c(67, 67, "3"), # direito
  c(68, 68, "6"), # agronomia
  c(70, 70, "3"), # ciências econômicas, contábeis e atuariais
  c(71, 71, "4"), # estatística
  c(72, 72, "8"), # artes domésticas
  c(73, 73, "7"), # saúde, enfermagem e serviços sanitários
  c(74, 74, "8"), # militar
  c(76, 76, "7"), # educação física (no Censo 2000, 100% área 7)
  c(78, 78, "2"), # eclesiástico
  c(79, 79, "0")  # outros: adm. pública, música, jornalismo, museologia
), "0")

area_1970 <- lookup(faixas(
  c(70, 70, "3"), c(71, 71, "6"), c(72, 72, "5"), c(73, 73, "2"),
  c(74, 74, "3"), c(75, 75, "2"),
  c(76, 76, "2"), # geografia ou história (agregadas no código)
  c(77, 77, "4"), c(78, 78, "2"), c(79, 79, "4"), c(80, 80, "1"),
  c(81, 83, "3"), c(84, 84, "2"), c(85, 86, "7"), c(87, 87, "5"),
  c(88, 88, "4"), c(89, 90, "7"), c(91, 91, "8"), c(92, 92, "7"),
  c(93, 93, "3"), c(94, 94, "5"), c(95, 95, "7"), c(96, 96, "6"),
  c(97, 97, "0")
), "0")

# 1980 (V525) e 1991 (V0329) usam a mesma grade de códigos 43-97
area_1980_1991 <- lookup(faixas(
  c(43, 43, "4"), # biologia
  c(44, 49, "7"), # ed. física, enfermagem, farmácia, medicina, odonto, outros
  c(50, 50, "5"), # arquitetura
  c(51, 52, "4"), # ciências exatas, computação
  c(53, 57, "5"), # engenharias
  c(58, 62, "4"), # estatística, física, geologia, matemática, química
  c(63, 63, "5"), # outros da tecnologia (Censo 2000: 74% área 5)
  c(64, 66, "6"), # agronomia, veterinária, outros de agrárias
  c(67, 73, "3"), # adm., bibliotec., contábeis, economia, sociais, comunic., direito
  c(74, 74, "2"), # filosofia
  c(75, 75, "4"), # geografia (Censo 2000: 94% área 4)
  c(76, 76, "2"), # história
  c(77, 77, "1"), # pedagogia
  c(78, 78, "3"), # psicologia
  c(79, 79, "7"), # serviço social
  c(80, 83, "2"), # teologia, outros de humanas, letras, artes
  c(84, 84, "8"), # militar
  c(85, 85, "0"), # outros cursos superiores
  c(86, 86, "7"), # mestrado/doutorado: medicina
  c(87, 87, "7"), #   outros (biologia)
  c(88, 88, "5"), #   engenharia
  c(89, 89, "4"), #   outros (ciências tecnológicas)
  c(90, 90, "6"), #   ciências agrárias
  c(91, 93, "3"), #   administração, economia/contábeis, direito
  c(94, 94, "1"), #   pedagogia
  c(95, 95, "3"), #   outros (humanas e sociais)
  c(96, 96, "2"), #   letras e artes
  c(97, 97, "0")  #   área não especificada
), "0")

# 2000 (V4354) e 2010 (V6352): código OCDE de 3 dígitos, área = 1º dígito.
# 085/097 (mal especificados) e NA caem em 0.
area_ocde <- function(x) {
  a <- as.character(as.integer(x) %/% 100)
  a[is.na(a) | !(a %in% names(AREAS))] <- "0"
  a
}

# --------------------------------------------------------------- setor ----

# Classificação de atividades de 1960 (V223B)
setor_1960 <- lookup(c(
  faixas(c(111, 219, "S01"), c(291, 292, "S01"), c(251, 259, "S02"),
         c(311, 339, "S03"), c(351, 351, "S05"), c(391, 392, "S04"),
         c(411, 429, "S06"), c(451, 459, "S09"), c(511, 511, "S08"),
         c(512, 516, "S14"), c(517, 517, "S13"), c(518, 518, "S09"),
         c(519, 519, "S14"), c(611, 629, "S07"), c(711, 712, "S11"),
         c(713, 714, "S12"), c(715, 715, "S04"), c(716, 716, "S10"),
         c(717, 717, "S12"), c(718, 729, "S14"), c(751, 752, "S09"),
         c(753, 753, "S12"), c(754, 754, "S09"), c(755, 755, "S12"),
         c(756, 759, "S09"), c(811, 859, "S10"), c(911, 912, "S14"),
         c(919, 919, "S99"))
), "S99")

# Classificação de atividades de 1970 (V045)
setor_1970 <- lookup(c(
  faixas(c(111, 222, "S01"), c(223, 223, "S99"), c(301, 306, "S02"),
         c(311, 334, "S03"), c(341, 342, "S05"), c(351, 352, "S04"),
         c(411, 424, "S06"), c(511, 512, "S08"), c(513, 516, "S14"),
         c(517, 517, "S13"), c(518, 518, "S09"), c(519, 519, "S14"),
         c(611, 620, "S07"), c(711, 712, "S11"), c(713, 714, "S12"),
         c(715, 715, "S04"), c(716, 716, "S10"), c(717, 717, "S12"),
         c(718, 721, "S14"), c(811, 827, "S10"), c(911, 916, "S09"),
         c(921, 922, "S09"), c(923, 923, "S12"), c(924, 924, "S09"),
         c(925, 925, "S12"), c(926, 928, "S09"), c(931, 932, "S14"),
         c(933, 934, "S99"))
), "S99")

# Classificação de atividades de 1980 (V532) e 1991 (V0347)
setor_1980_1991 <- lookup(c(
  faixas(c(11, 42, "S01"), c(50, 59, "S02"), c(100, 300, "S03"),
         c(340, 340, "S05"), c(351, 354, "S04"), c(410, 424, "S06"),
         c(451, 464, "S09"), c(471, 482, "S07"), c(511, 512, "S08"),
         c(521, 533, "S14"), c(541, 543, "S09"), c(544, 544, "S13"),
         c(545, 551, "S14"), c(552, 552, "S09"), c(571, 578, "S09"),
         c(581, 582, "S09"), c(583, 583, "S07"), c(584, 585, "S09"),
         c(586, 588, "S07"), c(589, 589, "S09"), c(610, 610, "S12"),
         c(611, 611, "S10"), c(612, 612, "S09"), c(613, 613, "S14"),
         c(614, 614, "S09"), c(615, 619, "S14"), c(621, 624, "S12"),
         c(631, 632, "S11"), c(711, 727, "S10"), c(801, 801, "S14"),
         c(901, 901, "S14"), c(902, 903, "S99"))
), "S99")

# CNAE-Domiciliar (2000, V4462): divisão = código de 5 dígitos %/% 1000
setor_cnae_dom1 <- lookup(c(
  faixas(c(1, 5, "S01"), c(10, 14, "S02"), c(15, 37, "S03"),
         c(40, 41, "S04"), c(45, 45, "S05"),
         c(50, 53, "S06"), # a CNAE-Dom 1.0 põe o varejo/atacado na divisão 53
         c(55, 55, "S08"), c(60, 64, "S07"), c(65, 74, "S09"),
         c(75, 75, "S10"), c(80, 80, "S11"), c(85, 85, "S12"),
         c(90, 90, "S04"), c(91, 93, "S14"), c(95, 95, "S13"),
         c(99, 99, "S14"))
), "S99")

# CNAE-Domiciliar 2.0 (2010, V6471)
setor_cnae_dom2 <- lookup(c(
  faixas(c(1, 3, "S01"), c(5, 9, "S02"), c(10, 33, "S03"),
         c(35, 39, "S04"), c(41, 43, "S05"), c(45, 48, "S06"),
         c(49, 53, "S07"), c(55, 56, "S08"), c(58, 60, "S09"),
         c(61, 61, "S07"), c(62, 82, "S09"), c(84, 84, "S10"),
         c(85, 85, "S11"), c(86, 88, "S12"), c(90, 96, "S14"),
         c(97, 97, "S13"), c(99, 99, "S14"))
), "S99")
