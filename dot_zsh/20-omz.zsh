export ZSH="$HOME/.oh-my-zsh"
# Vide : le prompt est rendu par starship (70-prompt.zsh). Un thème omz
# poserait son propre PROMPT et le masquerait.
ZSH_THEME=""
plugins=(git)

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
  # oh-my-zsh lance compinit lui-même (oh-my-zsh.sh:129) : pas de second appel.
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit && compinit
fi
