# Graduados nos Censos 1960–2022: regras e números (27/10/2026)

Prova datada: não se reescreve. Se uma regra mudar, nasce outro arquivo.

Fonte: `censobr` 1.0.0 (versão de dados `v1.0.0`), sete censos com microdados
de pessoas: 1960, 1970, 1980, 1991, 2000, 2010 e 2022 (versão pública).
Contagens são pessoas (soma do peso amostral). Universo: todas as idades com
superior completo — na prática, adultos.

## Quem conta como graduado

| Ano | Regra | Registros |
|---|---|---:|
| 1960 | `V214` (curso completo) 50–79, cursos de nível superior | 55.800 |
| 1970 | `V039` (espécie de curso concluído) 70–97; todos têm `V038` = 4 | 144.426 |
| 1980 | `V525` 43–96, ou `V524` = 8 (mestrado/doutorado), ou `V522` = 8 (cursando mestrado/doutorado) | 469.321 |
| 1991 | `V0329` 43–97, ou `V0328` = 8, ou `V0326` = 6 | 419.127 |
| 2000 | (`V0432` = 7 e `V0434` = 1), ou `V0432` = 8, ou `V0430` = 13 | 631.774 |
| 2010 | `V6400` = 4 (nível de instrução derivado pelo IBGE) | 1.126.886 |
| 2022 | `P0760` = 7 (igual a `P0770` = 4) | 2.161.344 |

Em 1980 e 1991 o "grau da última série concluída = superior" **não basta**:
ele inclui quem concluiu uma série do superior e não o curso (98 mil registros
em 1991). Vale o código do curso concluído.

## Condição na força de trabalho

| Ano | Ocupado | Desocupado | Fora | Período |
|---|---|---|---|---|
| 1960 | `V223` 2, 3, 5 | `V223` = 4 | `V220` 0, 1, 4–9 | semana, para quem trabalhou no ano |
| 1970 | `V043` = 7 e `V047` 1–3 | `V047` 4–5 | `V043` 0–6 | semana 25–31/08/1970 |
| 1980 | `V528` 1/5 e `V541` 1–3 | `V541` = 4, ou `V528` = 3 e `V529` 1–2 | demais com `V541` 5–6 ou `V529` 3–9 | última semana |
| 1991 | `V0345` 1–2 | `V0358` 1–2 | `V0358` 0, 3–9 | **12 meses** |
| 2000 | `V0439`–`V0443` = 1 | `V0455` = 1 | `V0455` = 2 | semana 23–29/07/2000 |
| 2010 | `V6910` = 1 | `V6910` = 2 | `V6900` = 2 | semana 25–31/07/2010 |
| 2022 | `P0950` = 1 | `P0950` = 0 | `P0930` = 0 | semana de referência, 14+ anos |

1991 é o único com referência de 12 meses: superestima ocupados e
subestima desocupados frente aos demais. Em 2022, quem produz só para o
próprio consumo não é ocupado (conceito da PNAD Contínua); até 2010 era.

## Posição, setor e área

Três classificações harmonizadas em `R/mapeamentos.R`, com o detalhe de cada
ano preservado ao lado (`posicao_detalhada`, `curso`, `atividade`):

- **Posição** (5 grupos): empregado, conta própria, empregador, não
  remunerado/consumo próprio, não declarado. Carteira e setor público só no
  detalhe: 1960/1970 separam público × particular; 1980 não separa nada;
  1991+ trazem carteira.
- **Setor** (15 grupamentos compatíveis com seções CNAE), mapeado de quatro
  classificações: 1960, 1970, 1980/1991 (mesma grade) e CNAE-Domiciliar 1.0
  (2000) e 2.0 (2010). Na CNAE-Dom 1.0 o comércio está na divisão 53, não 52.
- **Área de formação** (8 grandes áreas OCDE que o IBGE usa desde 2000, mais
  "não especificada"). Para 1960–1991, cada curso foi levado a uma área com o
  Censo 2000 como ponte: ele codifica a mesma pessoa na lista antiga (`V4355`)
  e na OCDE (`V4354`). Daí, por exemplo, Geografia → Ciências (94%), Educação
  Física → Saúde (100%), Serviço Social → Saúde e bem-estar (100%).

## O que não dá para comparar direto

1. **2022 não tem área de formação nem setor.** O microdado público omite
   `P0750` (curso) e `P0980`/`P1030` (atividade). Só o controlado, no IBGE,
   tem; o `censobr::import_microdata22()` lê esse arquivo para quem tiver acesso.
2. **Educação salta de 11% (2000) para 19% (2010)** por mudança de
   codificação, não de realidade: em 2010 as licenciaturas foram para
   "formação de professores" (145, 67 mil registros); em 2000 ficaram na
   disciplina (Letras → Humanidades, Matemática → Ciências). Antes de 2000 a
   lista de cursos nem separa licenciatura.
3. **1960 não tem Educação** porque pedagogia vem agregada a filosofia,
   ciências sociais e teologia no código 54 (→ "não especificada").
4. **Atividade mal definida em 2010: 6,3%** dos graduados ocupados (código 0
   no próprio dado), contra 0,4–1,3% nos outros anos.
5. **Área não especificada em 2010: 1,1 milhão**, código 85 e curso em branco.

## Números

Pessoas com superior completo:

| condição | 1960 | 1970 | 1980 | 1991 | 2000 | 2010 | 2022 |
|---|---:|---:|---:|---:|---:|---:|---:|
| Ocupado | 260.508 | 485.981 | 1.613.765 | 3.451.236 | 4.879.331 | 10.940.303 | 19.888.228 |
| Desocupado | 408 | 2.475 | 34.468 | 78.375 | 237.303 | 375.772 | 568.744 |
| Fora da força de trabalho | 30.173 | 71.239 | 220.352 | 549.856 | 936.509 | 2.147.682 | 5.419.701 |
| Não declarado | 0 | 293 | 0 | 0 | 0 | 0 | 0 |
| **Total** | **291.089** | **559.988** | **1.868.585** | **4.079.467** | **6.053.142** | **13.463.757** | **25.876.673** |
| Taxa de desocupação (%) | 0,16 | 0,51 | 2,09 | 2,22 | 4,64 | 3,32 | 2,78 |

Ocupados por posição:

| posição | 1960 | 1970 | 1980 | 1991 | 2000 | 2010 | 2022 |
|---|---:|---:|---:|---:|---:|---:|---:|
| Empregado | 155.124 | 364.121 | 1.299.178 | 2.670.859 | 3.457.732 | 8.492.783 | 14.815.933 |
| Conta própria | 77.472 | 79.418 | 174.829 | 416.561 | 906.067 | 1.808.969 | 3.790.769 |
| Empregador | 14.066 | 25.359 | 113.761 | 347.278 | 476.088 | 563.878 | 1.197.816 |
| Não remunerado / consumo próprio | 13.328 | 17.021 | 13.333 | 16.537 | 39.444 | 74.672 | 83.710 |
| Não declarado | 518 | 62 | 12.664 | 0 | 0 | 0 | 0 |

Graduados por área de formação (2022 indisponível):

| área | 1960 | 1970 | 1980 | 1991 | 2000 | 2010 |
|---|---:|---:|---:|---:|---:|---:|
| Ciências sociais, negócios e direito | 71.914 | 160.009 | 657.542 | 1.551.589 | 2.314.816 | 4.862.773 |
| Educação | 0 | 9.553 | 152.952 | 394.707 | 659.886 | 2.559.620 |
| Saúde e bem-estar social | 89.564 | 129.601 | 324.878 | 599.136 | 889.409 | 1.605.908 |
| Humanidades e artes | 27.251 | 83.601 | 228.022 | 462.360 | 659.999 | 954.682 |
| Engenharia, produção e construção | 47.235 | 88.061 | 216.530 | 430.281 | 567.093 | 928.041 |
| Ciências, matemática e computação | 7.824 | 6.295 | 103.658 | 330.051 | 546.265 | 934.294 |
| Agricultura e veterinária | 14.020 | 19.152 | 47.236 | 109.977 | 126.228 | 226.591 |
| Serviços (inclui militar) | 22.053 | 18.921 | 10.818 | 17.964 | 54.726 | 253.611 |
| Não especificada ou agregada | 11.229 | 44.795 | 126.949 | 183.402 | 234.722 | 1.138.237 |

Ocupados por setor (2022 indisponível):

| setor | 1960 | 1970 | 1980 | 1991 | 2000 | 2010 |
|---|---:|---:|---:|---:|---:|---:|
| Educação | 29.034 | 97.525 | 414.994 | 823.599 | 1.172.220 | 2.443.560 |
| Informação, finanças, imobiliárias, serv. profissionais e administrativos | 50.178 | 66.371 | 291.166 | 633.854 | 948.949 | 2.218.599 |
| Administração pública, defesa e seguridade social | 55.767 | 95.178 | 227.902 | 443.117 | 583.639 | 1.399.940 |
| Saúde humana e serviços sociais | 55.232 | 77.471 | 189.860 | 393.772 | 590.402 | 1.143.483 |
| Comércio e reparação de veículos | 14.723 | 22.953 | 76.820 | 285.347 | 487.482 | 1.042.077 |
| Indústrias de transformação | 18.796 | 52.376 | 203.743 | 375.791 | 392.381 | 720.842 |
| Atividade mal definida ou não declarada | 2.137 | 6.404 | 9.685 | 13.615 | 54.799 | 690.313 |
| Outros serviços | 13.571 | 19.473 | 39.174 | 114.451 | 176.982 | 345.872 |
| Transporte, armazenagem, correio e telecom. | 4.667 | 8.610 | 44.658 | 101.889 | 150.156 | 249.196 |
| Construção | 7.017 | 22.293 | 48.361 | 81.436 | 103.641 | 215.639 |
| Agropecuária, produção florestal e pesca | 5.853 | 6.886 | 20.304 | 54.354 | 68.938 | 160.625 |
| Alojamento e alimentação | 560 | 530 | 6.402 | 46.746 | 83.589 | 131.549 |
| Eletricidade, gás, água, esgoto e limpeza urbana | 2.057 | 8.018 | 32.094 | 58.195 | 49.172 | 83.155 |
| Indústrias extrativas | 904 | 1.837 | 8.051 | 21.017 | 12.544 | 66.477 |
| Serviços domésticos | 12 | 56 | 551 | 4.052 | 4.437 | 28.975 |

## Não verificado

Os totais não foram conferidos contra as tabelas publicadas do IBGE (SIDRA):
o acesso ao `apisidra.ibge.gov.br` estava bloqueado na sessão. É o primeiro
passo pendente no `ESTADO.md`.
