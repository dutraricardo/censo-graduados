"""Confere os totais de resultados/ contra as tabelas publicadas do IBGE (SIDRA).

Rodar na raiz do repositório: uv run --no-project python dados_aux/scripts/03_conferir_sidra.py
Grava resultados/13_conferencia_sidra.csv. Só a biblioteca padrão; precisa de
acesso a apisidra.ibge.gov.br. 1960, 1970 e 1980 não estão no SIDRA.

Nossos totais cobrem todas as idades; as tabelas do SIDRA começam em 10 ou
14 anos. Abaixo disso não há graduado, e a comparação vale como está.
"""

import csv
import json
import urllib.request
from collections import defaultdict

API = "https://apisidra.ibge.gov.br/values/"

# (ano, medida, tabela, consulta, categorias a somar, observação)
CONFERENCIAS = [
    (1991, "graduados", 145, "t/145/n1/all/v/141/p/1991/c136/2869,2870",
     "10 anos ou mais; grau do curso completo mais elevado superior ou mestrado/doutorado"),
    (2000, "graduados", 2983, "t/2983/n1/all/v/1644/p/2000/c12401/0",
     "pessoas com curso superior concluído; tabela por área de formação"),
    (2000, "graduados com curso de graduação informado", 2983,
     "t/2983/n1/all/v/1644/p/2000/c12401/0",
     "nosso total menos 'Curso não informado' (cursando mestrado/doutorado, V0430 = 13)"),
    (2010, "graduados", 3572, "t/3572/n1/all/v/140/p/2010/c1568/99713/c12056/0",
     "10 anos ou mais, superior completo"),
    (2010, "ocupados", 3585, "t/3585/n1/all/v/916/p/2010/c1568/99713",
     "10 anos ou mais, ocupados na semana de referência"),
    (2010, "desocupados", 3572, "t/3572/n1/all/v/140/p/2010/c1568/99713/c12056/99566",
     "economicamente ativos menos ocupados (3585)"),
    (2010, "fora_da_forca", 3572, "t/3572/n1/all/v/140/p/2010/c1568/99713/c12056/99567",
     "não economicamente ativos"),
    (2022, "graduados", 9517, "t/9517/n1/all/v/1641/p/2022/c1568/99713/c629/32385",
     "14 anos ou mais, superior completo"),
    (2022, "ocupados", 9517, "t/9517/n1/all/v/1641/p/2022/c1568/99713/c629/32387", ""),
    (2022, "desocupados", 9517, "t/9517/n1/all/v/1641/p/2022/c1568/99713/c629/32446", ""),
    (2022, "fora_da_forca", 9517, "t/9517/n1/all/v/1641/p/2022/c1568/99713/c629/32447", ""),
]


def sidra(consulta: str) -> int:
    with urllib.request.urlopen(API + consulta + "/f/n", timeout=120) as r:
        linhas = json.load(r)[1:]
    return sum(int(x["V"]) for x in linhas)


def nossos() -> dict[tuple[int, str], int]:
    v = {}
    with open("resultados/01_indicadores.csv", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            for m in ("graduados", "ocupados", "desocupados", "fora_da_forca"):
                v[int(r["ano"]), m] = int(r[m])
    sem_curso = defaultdict(float)
    with open("resultados/10_curso_condicao.csv", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            if r["curso"] == "Curso não informado":
                sem_curso[int(r["ano"])] += float(r["pessoas"])
    v[2000, "graduados com curso de graduação informado"] = (
        v[2000, "graduados"] - round(sem_curso[2000]))
    return v


def main() -> None:
    nosso = nossos()
    saida = []
    for ano, medida, tabela, consulta, obs in CONFERENCIAS:
        ibge = sidra(consulta)
        if (ano, medida) == (2010, "desocupados"):
            ibge -= sidra("t/3585/n1/all/v/916/p/2010/c1568/99713")
        n = nosso[ano, medida]
        dif = n - ibge
        saida.append({"ano": ano, "medida": medida, "tabela_sidra": tabela,
                      "nosso": n, "sidra": ibge, "diferenca": dif,
                      "diferenca_pct": round(100 * dif / ibge, 3), "observacao": obs})
        print(f"{ano} {medida:<45} nosso={n:>11,} sidra={ibge:>11,} dif={dif:>+9,}")
    with open("resultados/13_conferencia_sidra.csv", "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(saida[0]))
        w.writeheader()
        w.writerows(saida)


if __name__ == "__main__":
    main()
