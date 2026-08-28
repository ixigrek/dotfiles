export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="bureau"
plugins=(git)

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
  # oh-my-zsh lance compinit lui-même (oh-my-zsh.sh:129) : pas de second appel.
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit && compinit
fi
