# Thème Gruvbox Material, aligné sur ghostty (theme = Gruvbox Material)
# et sur les barres zjstatus (~/.config/zellij/config.kdl).
#
# ghostty tourne avec background-opacity 0.25 + macos-glass-regular :
# tous les fonds restent à -1 (transparent) pour ne pas casser le blur,
# seule la ligne sélectionnée reçoit un fond opaque.
typeset -gA GRUVBOX=(
  fg     '#d4be98'  bg1    '#32302f'  bg3    '#45403d'  bg4  '#504945'
  grey0  '#7c6f64'  grey1  '#928374'
  red    '#ea6962'  orange '#e78a4e'  yellow '#d8a657'
  green  '#a9b665'  aqua   '#89b482'  blue   '#7daea3'  purple '#d3869b'
)

export FZF_DEFAULT_OPTS="\
--color=fg:$GRUVBOX[fg],fg+:$GRUVBOX[fg],bg:-1,bg+:$GRUVBOX[bg3] \
--color=hl:$GRUVBOX[green],hl+:$GRUVBOX[green] \
--color=border:$GRUVBOX[bg4],separator:$GRUVBOX[bg4],label:$GRUVBOX[grey1] \
--color=preview-fg:$GRUVBOX[fg],preview-bg:-1,gutter:-1 \
--color=header:$GRUVBOX[blue],info:$GRUVBOX[aqua],spinner:$GRUVBOX[yellow] \
--color=prompt:$GRUVBOX[purple],pointer:$GRUVBOX[red],marker:$GRUVBOX[orange] \
--color=query:$GRUVBOX[fg] \
--prompt=' ' --pointer='▶' --marker='◆'"

# bat rend les previews fzf-tab. Thème maison :
# ~/.config/bat/themes/gruvbox-material-dark.tmTheme (`bat cache --build`),
# le "gruvbox-dark" livré avec bat étant le Gruvbox classique, trop saturé.
export BAT_THEME="gruvbox-material-dark"

# Colorisation des listings (ls + menu de complétion), en truecolor.
LS_COLORS="di=1;38;2;125;174;163:ln=38;2;211;134;155:ex=1;38;2;169;182;101"
LS_COLORS+=":so=38;2;211;134;155:pi=38;2;216;166;87:bd=38;2;231;138;78"
LS_COLORS+=":cd=38;2;231;138;78:su=1;38;2;234;105;98:sg=1;38;2;234;105;98"
LS_COLORS+=":tw=1;38;2;137;180;130:ow=1;38;2;137;180;130:or=1;38;2;234;105;98"
LS_COLORS+=":*.tar=38;2;234;105;98:*.gz=38;2;234;105;98:*.zip=38;2;234;105;98"
LS_COLORS+=":*.png=38;2;211;134;155:*.jpg=38;2;211;134;155:*.svg=38;2;211;134;155"
LS_COLORS+=":*.mp4=38;2;137;180;130:*.mp3=38;2;137;180;130"
LS_COLORS+=":*.md=38;2;216;166;87:*.json=38;2;216;166;87:*.toml=38;2;216;166;87"
export LS_COLORS

# eza lit LS_COLORS ci-dessus (c'est pour ça qu'il remplace le ls de macOS dans
# l'aperçu fzf-tab), mais garde des codes en dur pour deux détails hors norme
# GNU : la flèche des liens symboliques et le chemin de leur cible.
#   xx = ponctuation (la flèche ->)  -> grey0  #7c6f64
#   lp = chemin de la cible          -> blue   #7daea3, comme di
export EZA_COLORS="xx=38;2;124;111;100:lp=38;2;125;174;163"

# zsh-autosuggestions dans le gris "commentaire" de la palette.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=$GRUVBOX[grey0]"
