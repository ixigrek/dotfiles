# Prompt starship. Après oh-my-zsh (20-omz.zsh) qui, sans ZSH_THEME, ne pose
# plus de PROMPT — sinon le thème omz écraserait celui-ci.
# Config : ~/.config/starship.toml.
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"

  # starship enveloppe le widget zle-keymap-select existant pour redessiner le
  # prompt au changement de mode vi. Mais il s'initialise ici, avant l'init
  # différé de zsh-vi-mode : c'est zvm qui reposera le widget en dernier, et
  # l'enveloppe de starship sautera. D'où ce hook, fourni par zvm, qui force le
  # rafraîchissement — PROMPT est réévalué avec le $KEYMAP courant et le
  # symbole passe de ❯ à ❮.
  if (( $+functions[zvm_init] )); then
    function zvm_after_select_vi_mode() { zle reset-prompt }
  fi
fi
