#!/bin/sh
# Hook SessionStart do kit de protecao (ADR 0002 da estacao).
# A guarda de commit (.githooks) so roda com core.hooksPath configurado, e essa
# configuracao nao viaja no clone. Aqui ela e ativada em toda sessao: na maquina
# e na nuvem.
raiz=${CLAUDE_PROJECT_DIR:-.}
[ -d "$raiz/.githooks" ] || exit 0
atual=$(git -C "$raiz" config --get core.hooksPath 2>/dev/null)
if [ "$atual" = ".githooks" ]; then
  echo "Guarda de commit ativa (core.hooksPath=.githooks)."
else
  git -C "$raiz" config core.hooksPath .githooks \
    && echo "Guarda de commit ativada agora (core.hooksPath=.githooks)." \
    || echo "AVISO: nao foi possivel ativar a guarda de commit (core.hooksPath)."
fi
exit 0
