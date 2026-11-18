#!/bin/sh
# Teste de aceite dos hooks do kit (guarda.sh e sessao.sh).
# Uso: sh .claude/hooks/testar.sh     (sai com 1 se algum caso falhar)
aqui=$(cd "$(dirname "$0")" && pwd)
falhas=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Repositorio de teste: num branch de tarefa e, depois, no principal.
git -C "$tmp" init -q -b main 2>/dev/null || { git -C "$tmp" init -q; git -C "$tmp" checkout -q -b main; }
git -C "$tmp" -c user.name=t -c user.email=t@t commit -q --allow-empty -m inicio
git -C "$tmp" checkout -q -b tarefa

json() { printf '{"tool_name":"Bash","tool_input":{"command":"%s","description":"x"}}' "$1"; }

caso() { # esperado(0|2) arvore comando
  esperado=$1; arvore=$2; shift 2
  json "$*" | CLAUDE_PROJECT_DIR="$tmp" sh "$aqui/guarda.sh" "$arvore" 2>/dev/null
  obtido=$?
  if [ "$obtido" -ne "$esperado" ]; then
    echo "FALHOU ($arvore, esperado $esperado, veio $obtido): $*"
    falhas=$((falhas + 1))
  fi
}

# --- bloqueia
caso 2 institucional 'git commit --no-verify -m x'
caso 2 institucional 'git commit -n -m x'
caso 2 institucional 'git -C . commit --no-verify -m x'
caso 2 institucional 'git add -f data/base.xlsx'
caso 2 institucional 'git add --force x'
caso 2 institucional 'git clean -fdx'
caso 2 institucional 'cd /tmp && git clean -n'
caso 2 institucional 'git push origin main'
caso 2 institucional 'git push origin HEAD:master'
caso 2 institucional 'git -C . push -u origin main'
caso 2 institucional 'git push --all'
caso 2 institucional 'cat data/20260901/extracao.csv'
caso 2 institucional 'head -5 relatorio.xlsx'
caso 2 institucional 'Get-Content data\\\\base.csv'
caso 2 institucional 'uv run python x.py | grep -i nome data/a.parquet'
caso 2 pessoal 'git push origin main'
caso 2 pessoal 'git commit --no-verify -m x'

# --- deixa passar
caso 0 institucional 'git commit -m \\"corrige o filtro\\"'
caso 0 institucional 'git add src/app.py'
caso 0 institucional 'git push -u origin tarefa'
caso 0 institucional 'git push -u origin feature-main'
caso 0 institucional 'git status'
caso 0 institucional 'uv run python scripts/perfilar_tabelas.py'
caso 0 institucional 'uv run pytest -q'
caso 0 institucional 'cat README.md'
caso 0 institucional 'ls data/'
caso 0 pessoal 'sqlite3 passagens_202612/historico/precos.sqlite .tables'

# --- gh: bloqueia (ADR 0012)
caso 2 institucional 'gh repo delete dutraricardo/x --yes'
caso 2 institucional 'gh repo archive dutraricardo/x'
caso 2 institucional 'gh repo edit --visibility public'
caso 2 institucional 'gh secret set TOKEN'
caso 2 institucional 'gh auth token'
caso 2 institucional 'gh auth status --show-token'
caso 2 institucional 'gh auth status -t'
caso 2 institucional 'gh release delete v1'
caso 2 institucional 'gh issue delete 3'
caso 2 institucional 'gh api -X DELETE repos/dutraricardo/x'
caso 2 institucional 'gh api repos/dutraricardo/x/pulls/1/merge --method PUT'
caso 2 institucional 'gh api repos/dutraricardo/x/issues -f title=t'
caso 2 institucional 'gh api repos/dutraricardo/x -XDELETE'
caso 2 institucional 'gh api repos/dutraricardo/x/issues -ftitle=t'
caso 2 institucional 'gh alias set x \"repo delete dutraricardo/y --yes\"'
caso 2 institucional 'gh extension install alguem/gh-x'
caso 2 institucional 'gh pr merge 5 --merge --admin'
caso 2 pessoal 'gh repo delete dutraricardo/x --yes'
caso 2 pessoal 'gh auth token'

# --- gh: deixa passar
caso 0 institucional 'gh issue create --title t --body b'
caso 0 institucional 'gh project item-add 1 --owner dutraricardo --url u'
caso 0 institucional 'gh pr create --base main --title t --body b'
caso 0 institucional 'gh pr checks 5 --watch'
caso 0 institucional 'gh pr view 5'
caso 0 institucional 'gh auth status'
caso 0 institucional 'gh api repos/dutraricardo/x'
caso 0 institucional 'gh repo view dutraricardo/x --json isArchived'

# --- gh pr merge: passa, mas pede a aprovacao do Ricardo (permissionDecision ask)
pede() { # arvore comando
  arvore=$1; shift
  saida=$(json "$*" | CLAUDE_PROJECT_DIR="$tmp" sh "$aqui/guarda.sh" "$arvore" 2>/dev/null)
  obtido=$?
  if [ "$obtido" -ne 0 ] || ! printf '%s' "$saida" | grep -q '"permissionDecision":"ask"'; then
    echo "FALHOU ($arvore, esperado pedido de aprovacao, veio $obtido): $*"
    falhas=$((falhas + 1))
  fi
}
nao_pede() { # arvore comando
  arvore=$1; shift
  saida=$(json "$*" | CLAUDE_PROJECT_DIR="$tmp" sh "$aqui/guarda.sh" "$arvore" 2>/dev/null)
  if printf '%s' "$saida" | grep -q 'permissionDecision'; then
    echo "FALHOU ($arvore, pediu aprovacao sem merge): $*"
    falhas=$((falhas + 1))
  fi
}
pede institucional 'gh pr merge 5 --merge --delete-branch'
pede institucional 'sh -c \"gh pr merge 5\"'
pede pessoal 'gh pr merge 5 --merge'
nao_pede institucional 'gh pr view 5'
caso 2 institucional 'gh pr merge 5 && cat data/a.csv'

# --- push sem branch explicito, estando no principal
git -C "$tmp" checkout -q main
caso 2 institucional 'git push'
caso 2 institucional 'git push origin'
caso 0 institucional 'git push -u origin tarefa'
caso 0 institucional 'git push -u origin feature-main'

# --- sessao.sh ativa a guarda de commit
mkdir -p "$tmp/.githooks"
git -C "$tmp" config --unset core.hooksPath 2>/dev/null
CLAUDE_PROJECT_DIR="$tmp" sh "$aqui/sessao.sh" >/dev/null
if [ "$(git -C "$tmp" config --get core.hooksPath)" != ".githooks" ]; then
  echo "FALHOU: sessao.sh nao ativou core.hooksPath"
  falhas=$((falhas + 1))
fi

if [ "$falhas" -eq 0 ]; then
  echo "testar.sh: todos os casos passaram."
  exit 0
fi
echo "testar.sh: $falhas caso(s) falharam."
exit 1
