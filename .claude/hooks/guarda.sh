#!/bin/sh
# Guarda do kit de protecao (ADR 0002 da estacao). Hook PreToolUse do Claude Code
# para as ferramentas Bash e PowerShell, declarado em .claude/settings.json.
# Recebe na entrada padrao o JSON da chamada; sai com 2 para bloquear.
#
# Uso: sh guarda.sh institucional|pessoal sensivel|nenhum
#   O segundo argumento diz se o repositorio tem dado sensivel (ADR 0017 da
#   estacao). Sem ele, ou com outro valor, vale sensivel (falha fechada).
#
# Bloqueia o que a regra deny do settings.json nao alcanca (a doc avisa que deny
# de Bash "nao e fronteira de seguranca": git -C . push, sh -c '...' passam):
#   1. git commit --no-verify (ou -n)       a guarda de commit nao se desliga
#   2. git add -f / --force                 arquivo ignorado fica ignorado
#   3. git clean                            apaga o que o git nao conhece (dado)
#   4. git push para o principal            todo trabalho chega por PR (ADR 0007 da estacao)
#      (inclusive refs/heads/main e, com o repositorio onde o comando roda no
#      principal, push sem dizer o branch ou do HEAD); git push --force, -f,
#      --force-with-lease ou +branch (reescreve o historico no GitHub); refspec
#      com curinga no destino, fora de refs/tags/ (refs/heads/*, refs/*, *), ou
#      so ":" (envia os branches que casam, inclusive o principal) (issue #59)
#   5. (com dado sensivel) comando de terminal que le, copia ou envia arquivo de
#      dado: cat/head/Get-Content/grep/cp/Copy-Item/scp/curl/python -c/...
#      sobre data/, logs/, saida/ ou .csv .xlsx .parquet .sqlite etc. (ADR 0003
#      da estacao; saida/ pela issue #59)
#   6. gh que cria, apaga, arquiva ou edita repositorio, mostra o token, mexe
#      em segredo, escreve pela API direta ou publica arquivo (gist, release);
#      gh pr merge --admin (ADR 0012); com dado sensivel, gh sobre arquivo de dado
# E pede aprovacao do Ricardo (permissionDecision "ask") para gh pr merge e para
# o que descarta alteracao local: git reset --hard, git checkout -- <arquivo>,
# git checkout -f, git checkout . e git restore (fora o --staged sozinho).
#
# O que ela NAO pega: script que abre o arquivo por dentro (uv run python x.py).
# Isso e a regra do dado: o script imprime so agregado.
#
# Sem jq de proposito: roda no sh do Git for Windows e no Linux da nuvem (awk
# sem extensao do gawk). Teste de aceite: sh .claude/hooks/testar.sh
set -f
arvore=${1:-institucional}
sensivel=${2:-sensivel}
raiz=${CLAUDE_PROJECT_DIR:-.}

bloquear() {
  printf 'Bloqueado pela guarda da estacao (.claude/hooks/guarda.sh): %s\n' "$1" >&2
  exit 2
}

# Entrada lida pelo proprio shell (cada processo custa ~0,3 s no Git for Windows).
entrada=
while IFS= read -r l || [ -n "$l" ]; do entrada="$entrada $l"; done

# So o campo "command" do JSON; escapes viram texto simples. Nao e um parser.
# Um processo so (sed) faz a leitura inteira (issue #32):
#   - continuacao de linha (\ ou ` antes da quebra, LF ou CRLF) junta as linhas;
#   - no git commit/tag/merge/stash/notes e no gh, texto livre entre aspas depois de -m/--message/
#     -t/--title/-b/--body vira "q": um -n ou um data/ na mensagem nao e opcao
#     nem arquivo (issue #43). Em checkout -b e branch -m o argumento e nome de
#     ref e fica como veio (issue #69). Texto com $( ou crase fica: o shell
#     executa o que esta dentro;
#   - \n vira quebra de linha: cada linha e um subcomando, como no terminal;
#   - &&, ||, ; e | tambem viram quebra de linha;
#   - sai duas vezes: em minusculas (as regras valem sem diferenca de caixa) e,
#     depois da marca @@ORIGINAL@@, como veio (git -C e -c, grep -A e -a,
#     caminhos). A marca tem maiusculas: nunca aparece na copia em minusculas.
saida=$(sed -n -E \
  -e 's/.*"command"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/' \
  -e 't achou' -e 'd' -e ':achou' \
  -e 's/\\\\\\r\\n/ /g' -e 's/`\\r\\n/ /g' \
  -e 's/\\\\\\n/ /g' -e 's/`\\n/ /g' \
  -e 's/\\\\/\//g' -e 's/\\"/"/g' -e 's/\\[rt]/ /g' \
  -e ':msg' \
  -e 's/((^|[[:space:]"(])(git(\.exe)?[[:space:]]([^"'"'"';|&]*[[:space:]])?(commit|tag|merge|stash|notes)|gh(\.exe)?)([[:space:]][^"'"'"';|&]*)?[[:space:]])(-m|--message|-t|--title|-b|--body)[[:space:]=]*"[^"$`]*"/\1\9 q/' \
  -e 's/((^|[[:space:]"(])(git(\.exe)?[[:space:]]([^"'"'"';|&]*[[:space:]])?(commit|tag|merge|stash|notes)|gh(\.exe)?)([[:space:]][^"'"'"';|&]*)?[[:space:]])(-m|--message|-t|--title|-b|--body)[[:space:]=]*'"'"'[^'"'"']*'"'"'/\1\9 q/' \
  -e 't msg' \
  -e 's/\\n/\
/g' -e 's/&&/\
/g' -e 's/\|\|/\
/g' -e 's/;/\
/g' -e 's/\|/\
/g' \
  -e 'h' -e 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/' -e 'p' \
  -e 'x' -e 's/^/@@ORIGINAL@@\
/' -e 'p' <<FIM
$entrada
FIM
)
[ -n "$saida" ] || exit 0
linhas=${saida%%@@ORIGINAL@@*}
original=${saida#*@@ORIGINAL@@}

# tem: expressao regular (abre um grep; o texto vai por here-doc, sem outro
# processo). contem: trecho literal, sem processo, para so chamar o grep quando
# a palavra aparece no comando.
tem() { grep -Eiq "$1" <<FIM
$linhas
FIM
}
contem() { case "$linhas" in *"$1"*) return 0 ;; esac; return 1; }

# Pedido de aprovacao: vale o primeiro motivo; sai no fim, se nada bloquear.
pedir=
pede() { [ -n "$pedir" ] || pedir=$1; }

# Fim de palavra: espaco, aspas, ) de subshell ou fim da linha.
FIMP='([[:space:]"'"'"')]|$)'

# git com opcoes antes do subcomando (git -C x -c y=z commit ...), tambem pelo
# caminho completo, entre aspas ou nao ("C:/Program Files/Git/cmd/git.exe").
# Valor de opcao pode vir entre aspas, com espaco (git -C "C:/x y" push).
V='([[:space:]]+-[^[:space:]]+([[:space:]]+("[^"]*"|'"'"'[^'"'"']*'"'"'|[^-[:space:]][^[:space:]]*))?)*[[:space:]]+'
G='(^|[[:space:]"(/])git(\.exe)?"?'$V

# Push: awk sobre o comando como veio. Para cada git push, imprime
#   B principal | B todos | B forca   bloqueia
#   B incerto                         push do branch atual numa pasta que so o
#                                     shell resolve ($HOME, crase, %x%): bloqueia
#   H<tab>pasta<tab>pasta...          push do branch atual: decide pelo branch do
#                                     repositorio (cd e -C em ordem, como no git)
# Nome de branch entre aspas vale sem as aspas; caminho entre aspas, inteiro;
# ~ no comeco vira a pasta do usuario. cd dentro de ( ) ou $( ) nao vale fora.
PUSH='
function limpa(s) { gsub(/^[("'"'"'`$]+/, "", s); gsub(/["'"'"'`);]+$/, "", s); return s }
function nome(s,  b) { b = tolower(limpa(s)); sub(/.*\//, "", b); sub(/\.exe$/, "", b); return b }
# Valor de cd ou -C. Marca "incerto" o que so o shell expande.
function valor(  w, q) {
  w = t[i]; q = substr(w, 1, 1)
  if (q == "\"" || q == "'"'"'")
    while (i < n && (length(w) < 2 || substr(w, length(w)) != q)) { i++; w = w " " t[i] }
  incerto = (w ~ /[$`%]/)
  w = limpa(w)
  if (w ~ /^~(\/|$)/) w = ENVIRON["HOME"] substr(w, 2)
  return w
}
# Quantos ( abrem no comeco e quantos ) fecham no fim da palavra
function abre(s) { sub(/[^("'"'"'`$].*/, "", s); return gsub(/\(/, "", s) }
function fecha(s) { sub(/.*[^)"'"'"'`;]/, "", s); return gsub(/\)/, "", s) }
{
  n = split($0, t, /[ \t]+/)
  # profundidade de ( ) no comeco de cada palavra, seguindo de uma linha a outra
  for (i = 1; i <= n; i++) { prof += abre(t[i]); p[i] = prof; prof -= fecha(t[i]); if (prof < 0) prof = 0 }
  for (i = 1; i <= n; i++) {
    while (ncd > 0 && cdp[ncd] > p[i]) ncd--
    b = nome(t[i])
    if (b == "cd" || b == "set-location" || b == "sl" || b == "chdir" || b == "pushd" || b == "push-location") {
      pc = p[i]
      for (i++; i <= n && (t[i] == "" || t[i] ~ /^-/); i++) ;
      if (i <= n) { v = valor(); ncd++; cdv[ncd] = v; cdp[ncd] = pc; cdi[ncd] = incerto }
      continue
    }
    if (b != "git") continue
    dirs = ""; duvida = 0
    for (k = 1; k <= ncd; k++) { dirs = dirs "\t" cdv[k]; if (cdi[k]) duvida = 1 }
    for (i++; i <= n && (t[i] == "" || t[i] ~ /^["'"'"']?-/); i++) {
      o = limpa(t[i])
      if (o == "-C") { i++; dirs = dirs "\t" valor(); if (incerto) duvida = 1 }
      else if (o == "-c" || o == "--git-dir" || o == "--work-tree" || o == "--namespace") i++
    }
    if (i > n || nome(t[i]) != "push") continue
    pos = 0; ref = 0; tags = 0; cabeca = 0; pula = 0
    for (i++; i <= n; i++) {
      a = limpa(t[i]); la = tolower(a)
      if (a == "") continue
      if (pula) { pula = 0; continue }
      if (la ~ /^-/) {
        if (la == "-o" || la == "--push-option" || la == "--repo" || la == "--receive-pack" || la == "--exec") pula = 1
        else if (la ~ /^--force/ || (la !~ /^--/ && la !~ /^-o/ && la ~ /^-[a-z0-9]*f/)) print "B forca"
        else if (la == "--all" || la == "--mirror" || la == "--branches") print "B todos"
        else if (la == "--tags") tags = 1
        continue
      }
      if (++pos == 1) continue
      ref++
      r = a
      if (substr(r, 1, 1) == "+") { print "B forca"; r = substr(r, 2) }
      if (r == ":") { print "B todos"; continue }
      dst = r; k = index(r, ":")
      if (k) { src = substr(r, 1, k - 1); sub(/.*:/, "", dst) } else src = r
      # curinga so passa num destino de tag; * casa barras (refs/* pega o principal)
      if (index(dst, "*") && dst !~ /^refs\/tags\/[^*]/ && dst !~ /^refs\/tags\/\*$/) print "B curinga"
      ld = tolower(dst); sub(/^refs\/heads\//, "", ld)
      if (ld == "main" || ld == "master") print "B principal"
      if (dst == "" || (!k && (tolower(src) == "head" || src == "@"))) cabeca = 1
    }
    if (cabeca || (ref == 0 && !tags)) print (duvida ? "B incerto" : "H" dirs)
  }
}'

if contem git; then
  contem commit && tem "${G}commit([[:space:]].*)?[[:space:]](--no-verify|-n|-[a-zA-Z]*n[a-zA-Z]*)$FIMP" \
    && bloquear "git commit sem a guarda de commit (--no-verify). A guarda nao se desliga."
  contem add && tem "${G}add([[:space:]].*)?[[:space:]](-f|--force|-[a-zA-Z]*f[a-zA-Z]*)$FIMP" \
    && bloquear "git add -f. Arquivo ignorado continua ignorado."
  contem clean && tem "${G}clean$FIMP" \
    && bloquear "git clean. Apaga arquivo que o git nao conhece, inclusive dado."

  if contem push && tem "${G}push$FIMP"; then
    veredito=$(awk "$PUSH" <<FIM
$original
FIM
)
    case $veredito in *"B principal"*)
      bloquear "git push para o branch principal. O trabalho chega por PR (ADR 0007 da estacao)." ;;
    esac
    case $veredito in *"B todos"*)
      bloquear "git push --all/--mirror/--branches (ou o refspec \":\") inclui o branch principal." ;;
    esac
    case $veredito in *"B curinga"*)
      bloquear "git push com curinga no destino (refs/heads/*). Pode atualizar o principal sem PR." ;;
    esac
    case $veredito in *"B forca"*)
      bloquear "git push --force (ou -f, --force-with-lease, +branch). Reescreve o historico no GitHub." ;;
    esac
    case $veredito in *"B incerto"*)
      bloquear "git push sem dizer o branch, numa pasta que so o shell resolve (\$, crase, %). Diga o branch: git push origin <branch>." ;;
    esac
    # Push do branch atual: o do repositorio onde o comando roda. A base e a
    # pasta da sessao (campo cwd do JSON) ou a raiz; cd e -C somam a ela, como
    # no git. Caminho literal que nao existe vale a raiz.
    # No Windows o cwd vem com a barra invertida escapada (C:\\Claude\\x):
    # vira barra normal, que o git do Windows aceita (issue #59).
    base=$raiz
    case $entrada in *'"cwd"'*)
      c=${entrada#*\"cwd\"}; c=${c#*\"}; c=${c%%\"*}
      while :; do case $c in *'\\'*) c=${c%%'\\'*}/${c#*'\\'} ;; *) break ;; esac; done
      [ -n "$c" ] && base=$c ;;
    esac
    velho=$IFS; IFS='
'
    for v in $veredito; do
      case $v in H*) ;; *) continue ;; esac
      IFS='	'
      set --
      for d in ${v#H}; do set -- "$@" -C "$d"; done
      IFS=$velho
      atual=$(git -C "$base" "$@" rev-parse --abbrev-ref HEAD 2>/dev/null) \
        || atual=$(git -C "$raiz" "$@" rev-parse --abbrev-ref HEAD 2>/dev/null) \
        || atual=$(git -C "$raiz" rev-parse --abbrev-ref HEAD 2>/dev/null)
      if [ "$atual" = main ] || [ "$atual" = master ]; then
        bloquear "git push estando em $atual. Crie um branch e abra PR (ADR 0007 da estacao)."
      fi
    done
    IFS=$velho
  fi

  # Descarta alteracao local: pede aprovacao (decisao do Ricardo, issue #49).
  contem reset && tem "${G}reset([[:space:]].*)?[[:space:]]--hard$FIMP" \
    && pede "git reset --hard apaga as alteracoes nao comitadas."
  contem checkout && tem "${G}checkout([[:space:]].*)?[[:space:]](--|-f|--force|\.)$FIMP" \
    && pede "git checkout -- <arquivo> (ou -f, ou .) apaga as alteracoes nao comitadas."
  # checkout <ref> <arquivo> (dois nomes soltos, sem -b/-B/--orphan/-t/--track)
  # sobrescreve o arquivo com a versao do ref (issue #69)
  # (2>&1, >log e 2>$null sao redirecionamento, nao arquivo)
  contem checkout && tem "${G}checkout([[:space:]]+-[^[:space:]]+)*[[:space:]]+[^-[:space:]][^[:space:]]*[[:space:]]+([^-[:space:]<>&0-9]|[0-9]+[^0-9<>[:space:]])" \
    && ! tem "${G}checkout([[:space:]]+-[^[:space:]]+)*[[:space:]]+(-b|-B|--orphan|-t|--track)$FIMP" \
    && pede "git checkout <ref> <arquivo> sobrescreve o arquivo com a versao do ref e apaga as alteracoes nao comitadas."
  contem switch && tem "${G}switch([[:space:]].*)?[[:space:]](-f|--force|--discard-changes)$FIMP" \
    && pede "git switch -f (ou --discard-changes) apaga as alteracoes nao comitadas."
  contem stash && tem "${G}stash[[:space:]]+(drop|clear)$FIMP" \
    && pede "git stash drop/clear apaga alteracoes guardadas no stash."
  # restore: -S (staged) e -s (source) so se distinguem pela caixa: olha o original
  if contem restore && tem "${G}restore$FIMP"; then
    R="${G}restore([[:space:]].*)?[[:space:]]"
    if tem "${R}--staged$FIMP" || grep -Eq "${R}-[a-zA-Z]*S[a-zA-Z]*$FIMP" <<FIM
$original
FIM
    then
      tem "${R}--worktree$FIMP" || grep -Eq "${R}-[a-zA-Z]*W[a-zA-Z]*$FIMP" <<FIM
$original
FIM
    else
      true
    fi && pede "git restore <arquivo> apaga as alteracoes nao comitadas (--staged sozinho nao pede)."
  fi
fi

# gh (ADR 0012 da estacao): o que destroi, expoe o token, escreve pela API
# direta ou publica arquivo fica bloqueado; o merge passa, mas sempre pela
# aprovacao do Ricardo. Como no git: opcoes antes do subcomando (gh -R x ...)
# e gh pelo caminho completo, com ou sem .exe, entre aspas ou nao.
H='(^|[[:space:]"(/])gh(\.exe)?"?'$V
if contem gh; then
  contem repo && tem "${H}repo[[:space:]]+(create|new|delete|archive|unarchive|rename|edit)$FIMP" \
    && bloquear "gh repo create/delete/archive/rename/edit. Criar ou mudar repositorio e do Ricardo, pela web."
  contem secret && tem "${H}secret$FIMP" \
    && bloquear "gh secret. Segredo nao passa pelo Claude."
  if contem auth; then
    tem "${H}auth[[:space:]]+token$FIMP" \
      && bloquear "gh auth token. O token nao aparece no terminal."
    tem "${H}auth([[:space:]].*)?[[:space:]](--show-token|-t)([[:space:]\"'=]|\$)" \
      && bloquear "gh auth --show-token. O token nao aparece no terminal."
  fi
  # Subcomando com delete no nome: release delete-asset, project item-delete,
  # repo deploy-key delete... So na posicao de subcomando (segunda palavra, ou
  # terceira depois de deploy-key/autolink): --delete-branch e um argumento
  # como gh pr checkout delete-feature nao contam.
  contem delete && tem "${H}[a-z][a-z0-9-]*[[:space:]]+((deploy-key|autolink)[[:space:]]+)?[a-z0-9-]*delete[a-z0-9-]*$FIMP" \
    && bloquear "gh ... delete. Apagar no GitHub e do Ricardo, pela web."
  if contem api; then
    tem "${H}api([[:space:]].*)?[[:space:]](-x|--method)[[:space:]=]*\"?(post|put|patch|delete)" \
      && bloquear "gh api com escrita. Use o comando proprio do gh (issue, pr, project)."
    tem "${H}api([[:space:]].*)?[[:space:]](-f|--field([[:space:]\"=]|\$)|--raw-field|--input)" \
      && bloquear "gh api com campos (vira POST). Use o comando proprio do gh (issue, pr, project)."
  fi
  case $linhas in *alias*|*extension*|*[[:space:]]ext[[:space:]]*|*[[:space:]]ext)
    tem "${H}(alias|extension|ext)$FIMP" \
      && bloquear "gh alias/extension. Atalho ou extensao contornam a guarda." ;;
  esac
  contem gist && tem "${H}gist$FIMP" \
    && bloquear "gh gist. Publica arquivo fora do repositorio."
  contem release && tem "${H}release[[:space:]]+(create|new|upload|edit)$FIMP" \
    && bloquear "gh release create/upload/edit. Anexa arquivo no GitHub; release e do Ricardo, pela web."
  if contem merge; then
    tem "${H}pr[[:space:]]+merge([[:space:]].*)?[[:space:]]--admin$FIMP" \
      && bloquear "gh pr merge --admin. O merge passa pelo CI."
    tem "${H}pr[[:space:]]+merge$FIMP" \
      && pede "Merge no branch principal: so com a aprovacao do Ricardo (ADR 0012 da estacao). Confira CI verde e /code-review."
  fi
fi

# Com dado sensivel (qualquer arvore, ADR 0017): comando de terminal que le,
# copia ou envia arquivo de dado (ou de log de acesso, logs/, ou o que o projeto
# gera com dado real, saida/), e gh que manda esse arquivo ao GitHub. Pastas e extensoes de dado ficam so aqui; o
# awk so roda se houver cara de dado no comando.
PASTAS='data logs saida'
EXTENSOES='csv tsv xlsx xls xlsb xlsm parquet feather sqlite db sav dta sas7bdat accdb mdb'
if [ "$sensivel" != nenhum ]; then
  dado=
  for e in $PASTAS; do case $linhas in *"$e/"*) dado=1; break ;; esac; done
  if [ -z "$dado" ]; then
    for e in $EXTENSOES; do case $linhas in *".$e"*) dado=1; break ;; esac; done
  fi
  if [ -n "$dado" ]; then
    velho=$IFS
    set -- $EXTENSOES; IFS='|'; EXT="$*"; IFS=$velho
    set -- $PASTAS; IFS='|'; DIRS="$*"; IFS=$velho
    msg="arquivo de dado lido, copiado ou enviado pelo terminal, ou mandado ao GitHub. O Claude nao le dado real: rode o script que imprime so agregado (ADR 0003 da estacao)."
    # Palavra por palavra, depois do comando que le/copia/envia. Em grep, rg,
    # sed, awk e Select-String, o primeiro argumento e o padrao (ou o programa),
    # nao arquivo: grep -n "data/" ESTADO.md passa. No gh, so o que manda
    # arquivo (--body-file, -F, --input), nao o texto. $( e crase recomecam.
    awk -v ext="$EXT" -v dirs="$DIRS" '
      function limpa(s) { gsub(/^[("'"'"'`$]+/, "", s); gsub(/["'"'"'`);]+$/, "", s); return s }
      function dado(s) { s = tolower(s); return s ~ ("(^|[/=@])(" dirs ")/|[.](" ext ")$") }
      function lista(ferr, ops, tipo,  a, k) { split(ops, a, " "); for (k in a) O[ferr SUBSEP a[k]] = tipo }
      BEGIN {
        split("cat head tail less more type bat xxd od strings grep egrep fgrep rg awk gawk mawk sed cut sort uniq wc sqlite3 duckdb get-content gc select-string sls import-csv import-excel cp copy copy-item cpi mv move move-item mi scp rsync curl wget invoke-webrequest iwr invoke-restmethod irm", a, " ")
        for (k in a) L[a[k]] = 1
        # Ferramentas de busca: opcao seguida de e = padrao, f = arquivo, v = outro valor
        split("grep egrep fgrep", g, " ")
        for (k in g) { lista(g[k], "-e --regexp", "e"); lista(g[k], "-f --file", "f")
          lista(g[k], "-A -B -C -m -d -D --context --max-count --label --devices --directories --include --exclude --exclude-dir", "v") }
        lista("rg", "-e --regexp", "e"); lista("rg", "-f --file", "f")
        lista("rg", "-A -B -C -m -g -t -T -j -M -r -E --glob --type --type-not --max-count --replace --encoding --context --after-context --before-context --max-depth --sort", "v")
        lista("sed", "-e --expression", "e"); lista("sed", "-f --file", "f"); lista("sed", "-l --line-length", "v")
        split("awk gawk mawk", g, " ")
        for (k in g) { lista(g[k], "-f --file", "f"); lista(g[k], "-v -F --assign --field-separator", "v") }
        split("select-string sls", g, " ")
        for (k in g) { lista(g[k], "-pattern", "e"); lista(g[k], "-path -literalpath", "f")
          lista(g[k], "-encoding -context -culture -include -exclude", "v") }
        split("grep egrep fgrep rg sed awk gawk mawk select-string sls", a, " ")
        for (k in a) P[a[k]] = 1
      }
      {
        n = split($0, t, /[ \t]+/); cmd = ""; espera = ""
        for (i = 1; i <= n; i++) {
          if (t[i] ~ /^["'"'"']?(\$\(|`|\()/) cmd = ""
          w = limpa(t[i]); if (w == "") continue
          if (cmd == "") {
            b = tolower(w); sub(/.*\//, "", b); sub(/\.exe$/, "", b)
            if (b in L) { cmd = b; padrao = (b in P); espera = "" }
            else if (b == "gh") { cmd = "gh"; espera = "" }
            continue
          }
          if (espera != "") { if (espera == "f" && dado(w)) exit 3; espera = ""; continue }
          if (cmd == "gh") {
            o = tolower(w)
            if (o == "--body-file" || o == "-f" || o == "--input") espera = "f"
            else if (o ~ /^(--body-file|--input|-f)=/) { sub(/^[^=]*=/, "", w); if (dado(limpa(w))) exit 3 }
            continue
          }
          if (w ~ /^-./) {
            o = (cmd == "select-string" || cmd == "sls" || w ~ /^--/) ? tolower(w) : w
            # opcoes curtas juntas (grep -nA 3): vale a ultima letra
            if (padrao && !((cmd SUBSEP o) in O) && o ~ /^-[a-zA-Z][a-zA-Z]+$/ && cmd != "select-string" && cmd != "sls")
              o = "-" substr(o, length(o))
            if (padrao && ((cmd SUBSEP o) in O)) {
              espera = O[cmd SUBSEP o]
              # -e (padrao dado na opcao) e -f de grep/sed/awk (padrao no
              # arquivo): o primeiro argumento solto ja e arquivo
              if (espera == "e" || (espera == "f" && cmd != "select-string" && cmd != "sls")) padrao = 0
              continue
            }
            if (index(w, "=")) { sub(/^[^=]*=/, "", w); if (dado(limpa(w))) exit 3 }
            continue
          }
          if (padrao) { padrao = 0; continue }
          if (dado(w)) exit 3
        }
      }' <<FIM
$original
FIM
    [ $? -eq 3 ] && bloquear "$msg"
    # python -c com caminho de dado: o ; do codigo quebra a linha, entao vale
    # o comando inteiro (script com caminho de dado continua liberado)
    D="([[:space:]\"'=/@(]|^)($DIRS)/|\\.($EXT)([[:space:]\"')]|\$)"
    contem python && tem '(^|[[:space:]"(])python[0-9.]*(\.exe)?[[:space:]]+(-[^[:space:]]+[[:space:]]+)*-c([[:space:]"'"'"']|$)' \
      && tem "$D" && bloquear "$msg"
  fi
fi

# Aprovacao: o Claude Code abre a janela, mesmo no modo auto.
if [ -n "$pedir" ]; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$pedir"
fi
exit 0
