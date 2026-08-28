# En dernier : exec remplace le shell, rien ne s'exécute après.
# NO_ZELLIJ=1 permet de lancer un zsh interactif sans zellij (scripts, debug).
if [[ -o interactive ]] && [[ -z "$ZELLIJ" ]] && [[ -z "$NO_ZELLIJ" ]] \
   && command -v zellij >/dev/null; then
  exec zellij
fi
