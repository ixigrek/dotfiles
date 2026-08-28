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

# Keybindings fzf : Ctrl-R (historique), Alt-C (cd), Ctrl-F (fichiers).
# Ctrl-T, le défaut de fzf pour les fichiers, ne remonterait jamais jusqu'ici :
# zellij le capture pour le mode tab (config.kdl, shared_except "locked", qui
# réserve aussi Ctrl-p/n/h/s/b/o/g/q). Ctrl-F n'est bindé qu'en mode scroll.
# Même contrainte que fzf-tab ci-dessus : zvm réécrit tout à son init différé,
# d'où le passage par son hook quand le plugin est présent.
#
# L'ordre dans zvm_after_init_commands compte : enable-fzf-tab passe AVANT.
# fzf lie ensuite Tab à fzf-completion, mais mémorise au passage le binding
# précédent dans $fzf_default_completion (= fzf-tab-complete) et s'y rabat en
# l'absence du trigger `**`. Tab reste donc sur fzf-tab, et `**<TAB>` s'ajoute.
if command -v fzf >/dev/null 2>&1; then
  _fzf_keys='eval "$(fzf --zsh)"; bindkey "^F" fzf-file-widget'
  if (( $+functions[zvm_init] )); then
    zvm_after_init_commands+=("$_fzf_keys")
  else
    eval "$_fzf_keys"
  fi
  unset _fzf_keys
fi
