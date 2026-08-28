# Chargés après compinit (cf. 20-omz.zsh), fzf-tab en premier : il doit
# s'installer sur la complétion avant que les autres n'enveloppent les widgets.
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
  for p in fzf-tab zsh-syntax-highlighting zsh-autosuggestions zsh-vi-mode; do
    f="$BREW_PREFIX/share/$p/$p.zsh"
    [ -f "$f" ] || f="$BREW_PREFIX/share/$p/$p.plugin.zsh"
    [ -f "$f" ] && source "$f"
  done
  unset p f
  # zsh-vi-mode diffère son init au 1er prompt et réécrit alors TOUS les
  # keybindings : sans ça, Tab repasse à la complétion native.
  # On teste zvm_init (fourni par le plugin) et non zvm_before_init, qui est
  # un hook que l'utilisateur définit lui-même — donc toujours absent ici.
  if (( $+functions[enable-fzf-tab] )) && (( $+functions[zvm_init] )); then
    zvm_after_init_commands+=(enable-fzf-tab)
  fi
fi
