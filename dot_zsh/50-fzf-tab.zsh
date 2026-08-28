# Dépend de LS_COLORS et FZF_DEFAULT_OPTS définis en 40-theme.zsh.
if (( $+functions[enable-fzf-tab] )); then
  # fzf-tab remplace le menu de sélection natif de zsh
  zstyle ':completion:*' menu no
  zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
  zstyle ':completion:*:descriptions' format "%F{$GRUVBOX[blue]}[%d]%f"
  zstyle ':completion:*:warnings' format "%F{$GRUVBOX[red]}aucune correspondance%f"

  # Sans ça fzf-tab ignore FZF_DEFAULT_OPTS (lib/-ftb-fzf:38, défaut "no")
  # et repart sur les couleurs par défaut de fzf.
  zstyle ':fzf-tab:*' use-fzf-default-opts yes
  zstyle ':fzf-tab:*' switch-group '<' '>'

  # Aperçu : dossier -> listing, fichier texte -> bat, sinon type MIME.
  # $realpath est fourni par fzf-tab ; il est vide pour les complétions
  # non-fichier (branches git, options...), d'où les tests -d/-f.
  zstyle ':fzf-tab:*' fzf-preview '
    if [[ -d $realpath ]]; then
      ls -1 --color=always -- $realpath | head -200
    elif [[ -f $realpath ]]; then
      case ${$(file --mime-type -b -- $realpath)%%/*} in
        text) bat --style=numbers --color=always --line-range=:200 -- $realpath ;;
        inode) file -b -- $realpath ;;
        *) case $(file --mime-type -b -- $realpath) in
             application/json|application/javascript|application/xml|application/x-*sh|application/*+xml)
               bat --style=numbers --color=always --line-range=:200 -- $realpath ;;
             *) file -b -- $realpath ;;
           esac ;;
      esac
    fi'
  zstyle ':fzf-tab:*' fzf-flags --preview-window=right:60%:wrap
fi
