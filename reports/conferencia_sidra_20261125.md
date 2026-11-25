# Conferência dos totais contra o SIDRA (25/11/2026)

Prova datada: não se reescreve. Se um número mudar, nasce outro arquivo.

Compara `resultados/01_indicadores.csv` (números de
`reports/metodologia_20261027.md`) com as tabelas publicadas do IBGE no SIDRA,
nível Brasil. Script: `dados_aux/scripts/03_conferir_sidra.py`; saída:
`resultados/13_conferencia_sidra.csv`.

## Resultado

| ano | medida | tabela SIDRA | nosso | SIDRA | diferença |
|---|---|---:|---:|---:|---:|
| 1991 | graduados | 145 | 4.079.467 | 4.079.467 | 0 |
| 2000 | graduados | 2983 | 6.053.142 | 5.890.631 | +162.511 (2,8%) |
| 2000 | graduados com curso de graduação informado | 2983 | 5.890.630 | 5.890.631 | −1 |
| 2010 | graduados | 3572 | 13.463.757 | 13.463.757 | 0 |
| 2010 | ocupados | 3585 | 10.940.303 | 10.940.303 | 0 |
| 2010 | desocupados | 3572 − 3585 | 375.772 | 375.772 | 0 |
| 2010 | fora da força de trabalho | 3572 | 2.147.682 | 2.147.682 | 0 |
| 2022 | graduados | 9517 | 25.876.673 | 25.854.291 | +22.382 (0,09%) |
| 2022 | ocupados | 9517 | 19.888.228 | 19.863.018 | +25.210 (0,13%) |
| 2022 | desocupados | 9517 | 568.744 | 568.074 | +670 (0,12%) |
| 2022 | fora da força de trabalho | 9517 | 5.419.701 | 5.423.199 | −3.498 (0,06%) |

**1991 e 2010 batem exatamente**, inclusive a condição na força de trabalho de
2010. Confirma a regra de graduado desses anos e a de ocupação de 2010.

**2000: diferença explicada.** A tabela 2983 é montada por área de formação e
não inclui quem não tem curso de graduação informado. Tirado esse grupo
("Curso não informado" em `resultados/10_curso_condicao.csv`: 162.512 pessoas,
na regra de 2000 quem cursava mestrado ou doutorado, `V0430` = 13), a diferença
cai para 1, que é arredondamento da soma de pesos. A regra fica como está: essas
pessoas têm graduação concluída. Quem comparar o total de 2000 com o SIDRA deve
saber que o nosso é 2,8% maior por isso.

**2022: diferença pequena e não explicada.** O total é 0,09% maior; os
ocupados, 0,13%; e os fora da força, 0,06% menores. Como o total também difere,
não é só a regra de ocupação. Graduados com menos de 14 anos não explicam
22 mil pessoas. A hipótese a testar é a versão pública do microdado que o
`censobr` lê não ter exatamente o peso e a amostra das tabelas do IBGE. Testar exige rodar o R; esta
máquina não tem R instalado.

## Sem conferência

- **1960, 1970 e 1980** não estão no SIDRA. A conferência só é possível contra
  os volumes impressos do Censo (por exemplo, a série Estatísticas do Século XX
  do IBGE).
- **1991 e 2000 por condição de atividade**: não achamos no SIDRA tabela com
  nível de instrução e condição de atividade para esses anos.

## De passagem

O SIDRA publica a área de formação de 2022 (tabelas 10063 a 10065: área geral,
específica e detalhada, por idade, sexo e cor), que o microdado público não tem.
Dá o total por área, mas não área × condição de ocupação ou setor; para isso,
ainda só o microdado controlado.
