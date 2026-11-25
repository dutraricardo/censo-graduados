Como `rotulos_dicionario.csv` foi gerado (uma vez, em 27/10/2026):

1. `censobr::data_dictionary(ano, dataset = "microdata")` para cada censo
   (baixa os .xlsx para o cache do censobr).
2. `python 01_dicionarios_para_texto.py` converte cada .xlsx em `dict_<ano>.txt`
   (ajuste o caminho do cache no glob). Para 1960, use `read_only=True` e
   `ws.reset_dimensions()`: o arquivo declara dimensão errada.
3. `python 02_extrair_rotulos.py rotulos_dicionario.csv`, na pasta dos .txt.

`03_conferir_sidra.py` (25/11/2026) confere os totais de `resultados/` contra
as tabelas do SIDRA e grava `resultados/13_conferencia_sidra.csv`. Rodar na
raiz do repositório: `uv run --no-project python dados_aux/scripts/03_conferir_sidra.py`.
Leitura do resultado: `reports/conferencia_sidra_20261125.md`.
