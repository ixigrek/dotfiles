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
  #
  # Le listing passe par eza et non par ls : le ls de macOS est un BSD ls, qui
  # ignore LS_COLORS (format GNU) et lit LSCOLORS — limité aux 8 couleurs ANSI,
  # donc incapable de rendre la palette truecolor de 40-theme.zsh, et qui
  # affichait les fichiers en noir sur blanc. eza lit LS_COLORS directement :
  # l'aperçu et le panneau de navigation (colorisé par le zstyle list-colors
  # ci-dessus) partagent enfin la même source de vérité.
  # $realpath est fourni par fzf-tab ; il n'est défini que pour les complétions
  # de fichiers (lib/-ftb-preview.tpl le pose seulement si ctxt[realdir] existe),
  # d'où les tests -d/-f.
  #
  # Pour tout le reste (sous-commandes, options, branches git...), la fenêtre
  # restait dessinée mais vide. On y met la description complète : fzf-tab
  # exporte $word et $desc, et $desc contient la ligne entière — celle que fzf
  # tronque en "··" dans la liste faute de largeur.
  zstyle ':fzf-tab:*' fzf-preview '
    if [[ -d $realpath ]]; then
      if (( $+commands[eza] )); then
        eza -1 --color=always --classify=always --group-directories-first \
            --no-quotes -- $realpath | head -200
      else
        ls -1 -- $realpath | head -200
      fi
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
    else
      printf "\033[1m%s\033[0m\n" $word
      if [[ $desc == *"-- "* ]]; then
        print -r --
        print -r -- ${desc#*-- }
      fi
    fi'
  # 50 % et non 60 : la description tient largement, et la liste regagne la
  # place qu'elle perdait à tronquer.
  zstyle ':fzf-tab:*' fzf-flags --preview-window=right:50%:wrap
fi
