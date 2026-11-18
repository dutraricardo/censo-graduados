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
#   6. gh que cria, apaga, arquiva ou edita repositorio, mostra o token, mexe
#      em segredo, escreve pela API direta ou publica arquivo (gist, release);
#      gh pr merge --admin (ADR 0012); no institucional, gh sobre arquivo de dado
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
# Um processo so (sed) faz a leitura inteira (issue #32: cada processo custa
# ~0,3 s no Git for Windows):
#   - continuacao de linha (\ ou ` antes da quebra) junta as duas linhas;
#   - \n vira quebra de linha: cada linha e um subcomando, como no terminal;
#   - &&, ||, ; e | tambem viram quebra de linha;
#   - tudo em minusculas (os testes abaixo valem sem diferenca de caixa).
linhas=$(tr '\n' ' ' | sed -n -E \
  -e 's/.*"command"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/' \
  -e 't achou' -e 'd' -e ':achou' \
  -e 's/\\\\\\n/ /g' -e 's/`\\n/ /g' \
  -e 's/\\\\/\//g' -e 's/\\"/"/g' -e 's/\\[rt]/ /g' \
  -e 's/\\n/\
/g' -e 's/&&/\
/g' -e 's/\|\|/\
/g' -e 's/;/\
/g' -e 's/\|/\
/g' \
  -e 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/' -e p)
[ -n "$linhas" ] || exit 0

# tem: expressao regular (abre um grep). contem: trecho literal, sem processo,
# para so chamar o grep quando a palavra aparece no comando.
tem() { printf '%s\n' "$linhas" | grep -Eiq "$1"; }
contem() { case "$linhas" in *"$1"*) return 0 ;; esac; return 1; }

# git com opcoes antes do subcomando (git -C x -c y=z commit ...)
G='(^|[[:space:]"(])git(\.exe)?([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+'

if contem git; then
  contem commit && tem "${G}commit([[:space:]].*)?[[:space:]](--no-verify|-n|-[a-zA-Z]*n[a-zA-Z]*)([[:space:]\"]|\$)" \
    && bloquear "git commit sem a guarda de commit (--no-verify). A guarda nao se desliga."
  contem add && tem "${G}add([[:space:]].*)?[[:space:]](-f|--force|-[a-zA-Z]*f[a-zA-Z]*)([[:space:]\"]|\$)" \
    && bloquear "git add -f. Arquivo ignorado continua ignorado."
  contem clean && tem "${G}clean([[:space:]\"]|\$)" \
    && bloquear "git clean. Apaga arquivo que o git nao conhece, inclusive dado."

  if contem push && tem "${G}push([[:space:]\"]|\$)"; then
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
fi

# gh (ADR 0012 da estacao): o que destroi, expoe o token, escreve pela API
# direta ou publica arquivo fica bloqueado; o merge passa, mas sempre pela
# aprovacao do Ricardo.
H='(^|[[:space:]"(])gh(\.exe)?[[:space:]]+'
pedir_merge=
if contem gh; then
  contem repo && tem "${H}repo[[:space:]]+(create|new|delete|archive|unarchive|rename|edit)([[:space:]\"]|\$)" \
    && bloquear "gh repo create/delete/archive/rename/edit. Criar ou mudar repositorio e do Ricardo, pela web."
  contem secret && tem "${H}secret([[:space:]\"]|\$)" \
    && bloquear "gh secret. Segredo nao passa pelo Claude."
  if contem auth; then
    tem "${H}auth[[:space:]]+token([[:space:]\"]|\$)" \
      && bloquear "gh auth token. O token nao aparece no terminal."
    tem "${H}auth([[:space:]].*)?[[:space:]](--show-token|-t)([[:space:]\"=]|\$)" \
      && bloquear "gh auth --show-token. O token nao aparece no terminal."
  fi
  contem delete && tem "${H}(release|run|cache|label|issue|variable|project)[[:space:]]+delete([[:space:]\"]|\$)" \
    && bloquear "gh ... delete. Apagar no GitHub e do Ricardo, pela web."
  if contem api; then
    tem "${H}api([[:space:]].*)?[[:space:]](-x|--method)[[:space:]=]*\"?(post|put|patch|delete)" \
      && bloquear "gh api com escrita. Use o comando proprio do gh (issue, pr, project)."
    tem "${H}api([[:space:]].*)?[[:space:]](-f|--field([[:space:]\"=]|\$)|--raw-field|--input)" \
      && bloquear "gh api com campos (vira POST). Use o comando proprio do gh (issue, pr, project)."
  fi
  { contem alias || contem ext; } && tem "${H}(alias|extension|ext)([[:space:]\"]|\$)" \
    && bloquear "gh alias/extension. Atalho ou extensao contornam a guarda."
  contem gist && tem "${H}gist([[:space:]\"]|\$)" \
    && bloquear "gh gist. Publica arquivo fora do repositorio."
  contem release && tem "${H}release[[:space:]]+(create|new|upload|edit)([[:space:]\"]|\$)" \
    && bloquear "gh release create/upload/edit. Anexa arquivo no GitHub; release e do Ricardo, pela web."
  if contem merge; then
    tem "${H}pr[[:space:]]+merge([[:space:]].*)?[[:space:]]--admin([[:space:]\"]|\$)" \
      && bloquear "gh pr merge --admin. O merge passa pelo CI."
    tem "${H}pr[[:space:]]+merge([[:space:]\"]|\$)" && pedir_merge=1
  fi
fi

# Institucional: comando de terminal (ou gh, que manda arquivo ao GitHub) sobre
# arquivo de dado. So abre grep se houver cara de dado no comando.
if [ "$arvore" = institucional ]; then
  case "$linhas" in
    *data/*|*.csv*|*.tsv*|*.xls*|*.parquet*|*.feather*|*.sqlite*|*.db*|*.sav*|*.dta*|*.sas7bdat*|*.accdb*|*.mdb*)
      L='(^|[[:space:]"(])(cat|head|tail|less|more|type|bat|xxd|od|strings|grep|egrep|rg|awk|sed|cut|sort|uniq|wc|sqlite3|duckdb|get-content|gc|select-string|sls|import-csv|import-excel|gh)(\.exe)?[[:space:]]'
      D='([[:space:]"'"'"'=/]|^)data/|\.(csv|tsv|xlsx|xls|xlsb|xlsm|parquet|feather|sqlite|db|sav|dta|sas7bdat|accdb|mdb)([[:space:]"'"'"']|$)'
      printf '%s\n' "$linhas" | while IFS= read -r l; do
        if printf '%s\n' "$l" | grep -Eiq "$L" && printf '%s\n' "$l" | grep -Eiq "$D"; then
          exit 3
        fi
      done
      [ $? -eq 3 ] && bloquear "arquivo de dado lido no terminal ou mandado ao GitHub. O Claude nao le dado real: rode o script que imprime so agregado (ADR 0003 da estacao)."
      ;;
  esac
fi

# Merge: o Claude Code abre a janela de aprovacao, mesmo no modo auto.
if [ -n "$pedir_merge" ]; then
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Merge no branch principal: so com a aprovacao do Ricardo (ADR 0012 da estacao). Confira CI verde e /code-review."}}'
fi
exit 0
