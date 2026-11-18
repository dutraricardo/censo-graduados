#!/bin/sh
# Guarda do kit de protecao (ADR 0002 da estacao). Hook PreToolUse do Claude Code
# para as ferramentas Bash e PowerShell, declarado em .claude/settings.json.
# Recebe na entrada padrao o JSON da chamada; sai com 2 para bloquear.
#
# Uso: sh guarda.sh institucional|pessoal
#
# Bloqueia o que a regra deny do settings.json nao alcanca (a doc avisa que deny
# de Bash "nao e fronteira de seguranca": git -C . push, sh -c '...' passam):
#   1. git commit --no-verify (ou -n)       a guarda de commit nao se desliga
#   2. git add -f / --force                 arquivo ignorado fica ignorado
#   3. git clean                            apaga o que o git nao conhece (dado)
#   4. git push para o principal            todo trabalho chega por PR (ADR 0007 da estacao)
#   5. (institucional) comando de terminal que le arquivo de dado direto:
#      cat/head/tail/less/more/type/Get-Content/grep/... sobre data/ ou sobre
#      .csv .xlsx .parquet .sqlite etc. (ADR 0003 da estacao)
#   6. gh que apaga, arquiva ou edita repositorio, mostra o token, mexe em
#      segredo ou escreve pela API direta; gh pr merge --admin (ADR 0012)
# E pede aprovacao do Ricardo (permissionDecision "ask") para todo gh pr merge.
#
# O que ela NAO pega: script que abre o arquivo por dentro (uv run python x.py).
# Isso e a regra do dado: o script imprime so agregado.
#
# Sem jq de proposito: roda no sh do Git for Windows e no Linux da nuvem.
# Teste de aceite: sh .claude/hooks/testar.sh
set -f
arvore=${1:-institucional}

bloquear() {
  printf 'Bloqueado pela guarda da estacao (.claude/hooks/guarda.sh): %s\n' "$1" >&2
  exit 2
}

# So o campo "command" do JSON; escapes viram texto simples. Nao e um parser.
cmd=$(tr '\n' ' ' | sed -n -E 's/.*"command"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' \
  | sed -e 's/\\\\/\//g' -e 's/\\"/"/g' -e 's/\\[nrt]/ /g')
[ -n "$cmd" ] || exit 0

# Separadores de comando viram quebra de linha: cada linha e um subcomando.
linhas=$(printf '%s\n' "$cmd" | sed -e 's/&&/\
/g' -e 's/||/\
/g' -e 's/;/\
/g' -e 's/|/\
/g')

tem() { printf '%s\n' "$linhas" | grep -Eiq "$1"; }

# git com opcoes antes do subcomando (git -C x -c y=z commit ...)
G='(^|[[:space:]"(])git(\.exe)?([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+'

tem "${G}commit([[:space:]].*)?[[:space:]](--no-verify|-n|-[a-zA-Z]*n[a-zA-Z]*)([[:space:]\"]|\$)" \
  && bloquear "git commit sem a guarda de commit (--no-verify). A guarda nao se desliga."
tem "${G}add([[:space:]].*)?[[:space:]](-f|--force|-[a-zA-Z]*f[a-zA-Z]*)([[:space:]\"]|\$)" \
  && bloquear "git add -f. Arquivo ignorado continua ignorado."
tem "${G}clean([[:space:]\"]|\$)" \
  && bloquear "git clean. Apaga arquivo que o git nao conhece, inclusive dado."

if tem "${G}push([[:space:]\"]|\$)"; then
  tem "${G}push([[:space:]].*)?[[:space:]:+](main|master)([[:space:]\"]|\$)" \
    && bloquear "git push para o branch principal. O trabalho chega por PR (ADR 0007 da estacao)."
  tem "${G}push([[:space:]].*)?[[:space:]]--(all|mirror)([[:space:]\"]|\$)" \
    && bloquear "git push --all/--mirror inclui o branch principal."
  # push sem dizer o branch, estando no principal
  raiz=${CLAUDE_PROJECT_DIR:-.}
  atual=$(git -C "$raiz" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ "$atual" = main ] || [ "$atual" = master ]; then
    args=$(printf '%s\n' "$linhas" | grep -Ei "${G}push" | head -n 1 \
      | sed -E 's/.*[[:space:]]push//' | tr ' ' '\n' | grep -v '^-' | grep -v '^$' | wc -l)
    [ "$args" -le 1 ] && bloquear "git push estando em $atual. Crie um branch e abra PR (ADR 0007 da estacao)."
  fi
fi

# gh (ADR 0012 da estacao): o que destroi, expoe o token ou escreve pela API
# direta fica bloqueado; o merge passa, mas sempre pela aprovacao do Ricardo.
H='(^|[[:space:]"(])gh(\.exe)?[[:space:]]+'
tem "${H}repo[[:space:]]+(delete|archive|unarchive|rename|edit)([[:space:]\"]|\$)" \
  && bloquear "gh repo delete/archive/rename/edit. Mudanca no repositorio e do Ricardo, pela web."
tem "${H}secret([[:space:]\"]|\$)" \
  && bloquear "gh secret. Segredo nao passa pelo Claude."
tem "${H}auth[[:space:]]+token([[:space:]\"]|\$)" \
  && bloquear "gh auth token. O token nao aparece no terminal."
tem "${H}auth([[:space:]].*)?[[:space:]](--show-token|-t)([[:space:]\"=]|\$)" \
  && bloquear "gh auth --show-token. O token nao aparece no terminal."
tem "${H}(release|run|cache|label|issue|variable)[[:space:]]+delete([[:space:]\"]|\$)" \
  && bloquear "gh ... delete. Apagar no GitHub e do Ricardo, pela web."
tem "${H}api([[:space:]].*)?[[:space:]](-X|--method)[[:space:]=]*\"?(POST|PUT|PATCH|DELETE)" \
  && bloquear "gh api com escrita. Use o comando proprio do gh (issue, pr, project)."
tem "${H}api([[:space:]].*)?[[:space:]](-f|-F|--field([[:space:]\"=]|\$)|--raw-field|--input)" \
  && bloquear "gh api com campos (vira POST). Use o comando proprio do gh (issue, pr, project)."
tem "${H}(alias|extension|ext)([[:space:]\"]|\$)" \
  && bloquear "gh alias/extension. Atalho ou extensao contornam a guarda."
tem "${H}pr[[:space:]]+merge([[:space:]].*)?[[:space:]]--admin([[:space:]\"]|\$)" \
  && bloquear "gh pr merge --admin. O merge passa pelo CI."
pedir_merge=
tem "${H}pr[[:space:]]+merge([[:space:]\"]|\$)" && pedir_merge=1

if [ "$arvore" = institucional ]; then
  L='(^|[[:space:]"(])(cat|head|tail|less|more|type|bat|xxd|od|strings|grep|egrep|rg|awk|sed|cut|sort|uniq|wc|sqlite3|duckdb|Get-Content|gc|Select-String|sls|Import-Csv|Import-Excel)(\.exe)?[[:space:]]'
  D='([[:space:]"'"'"'=/\\]|^)data[/\\]|\.(csv|tsv|xlsx|xls|xlsb|xlsm|parquet|feather|sqlite|db|sav|dta|sas7bdat|accdb|mdb)([[:space:]"'"'"']|$)'
  printf '%s\n' "$linhas" | while IFS= read -r l; do
    if printf '%s\n' "$l" | grep -Eiq "$L" && printf '%s\n' "$l" | grep -Eiq "$D"; then
      exit 3
    fi
  done
  [ $? -eq 3 ] && bloquear "leitura direta de arquivo de dado. O Claude nao le dado real: rode o script que imprime so agregado (ADR 0003 da estacao)."
fi

# Merge: o Claude Code abre a janela de aprovacao, mesmo no modo auto.
if [ -n "$pedir_merge" ]; then
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Merge no branch principal: so com a aprovacao do Ricardo (ADR 0012 da estacao). Confira CI verde e /code-review."}}'
fi
exit 0
