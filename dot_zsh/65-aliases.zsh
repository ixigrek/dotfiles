# Alias de listing : eza remplace ls dans le shell interactif.
# Après 20-omz, qui pose ses propres `ls`, `l`, `ll`, `la` et `lsa`
# (lib/theme-and-appearance.zsh et lib/directories.zsh) — il faut passer
# après lui pour les écraser. Avant l'exec de 90-zellij, évidemment.
#
# Un alias ne vit que dans l'instance interactive qui le définit : il n'est
# pas exporté, et un script (`#!/bin/bash`, `#!/bin/sh`, ou `zsh script.zsh`)
# démarre un shell non interactif qui ne lit pas ~/.zshrc. Les scripts voient
# donc toujours le vrai /bin/ls. C'est pour ça qu'on aliase plutôt que de
# poser un shim `ls` dans le PATH, qui lui casserait make, configure, les
# hooks git et tout ce qui appelle ls en supposant la syntaxe POSIX.
#
# Échappatoires quand le vrai binaire est nécessaire : \ls, 'ls', command ls.
#
# Attention en revanche aux lettres que eza réutilise avec un autre sens :
#   -h  ls: tailles humaines   | eza: ligne d'en-tête (tailles humaines par défaut)
#   -t  ls: tri par date       | eza: --time <FIELD>, exige une valeur → erreur
#   -S  ls: tri par taille     | eza: --blocksize
#   -G  ls (BSD): couleur      | eza: grille
# D'où le tri explicite via --sort ci-dessous plutôt que -t / -S.
#
# Les couleurs viennent de LS_COLORS + EZA_COLORS (40-theme.zsh).
# `auto` partout : eza détecte l'absence de TTY et retombe sur une entrée par
# ligne, sans couleur ni icône — donc `for f in $(ls)` continue de marcher.
# Les icônes supposent une Nerd Font (ghostty embarque JetBrains Mono NF).
#
# Une différence de comportement à connaître (eza 0.23.5) : sans argument de
# chemin et avec un stdin qui n'est pas un TTY, eza lit les noms de fichiers
# sur son entrée standard au lieu de lister le répertoire courant. `ls` seul
# ne renvoie donc rien sous `NO_ZELLIJ=1 zsh -ic 'ls'` (cf. 90-zellij.zsh) ou
# derrière un `< /dev/null`. Au prompt, stdin est le terminal : `ls`, `ls |
# grep x` et `$(ls)` se comportent normalement. Parade dans ces cas-là :
# passer le chemin explicitement — `ls .`.

if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first --classify=auto --icons=auto'
  alias l='eza -la --group-directories-first --icons=auto --git'
  alias ll='eza -l  --group-directories-first --icons=auto --git'
  alias la='eza -la --group-directories-first --icons=auto --git'
  alias lsa='eza -la --group-directories-first --icons=auto'

  # Tri : --sort évite le piège -t / -S décrit plus haut.
  alias lt='eza -l --group-directories-first --icons=auto --sort=modified --reverse'
  alias lS='eza -l --group-directories-first --icons=auto --sort=size --reverse'

  # Arborescence. --git-ignore pour ne pas noyer l'affichage dans node_modules
  # et consorts ; `tree` (le binaire du Brewfile) reste dispo pour le reste.
  alias lT='eza --tree --level=2 --group-directories-first --icons=auto --git-ignore'
fi

# --- Raccourcis Kubernetes ---
# Trois lettres pour les trois CLI utilisées en boucle. Elles héritent du
# contexte posé par direnv (`use kube` → KUBECONFIG, cf. ~/.config/direnv/
# direnvrc) sans rien avoir à faire : ce sont de simples alias, l'environnement
# du shell les suit.
#
# Pas de `compdef k=kubectl` : COMPLETE_ALIASES est désactivé (défaut zsh, et
# oh-my-zsh ne le pose pas), donc zsh développe l'alias avant de chercher la
# complétion — `k get po<TAB>` passe déjà par _kubectl. Poser l'option
# inverserait ce comportement et casserait ces trois lignes d'un coup.
# Les trois fonctions _kubectl / _helm / _argocd viennent des site-functions de
# brew, déjà dans le fpath (10-completion.zsh) : rien à générer dans ~/.zfunc.
#
# Noms d'une lettre : vérifier `whence -v k h a` avant d'en ajouter d'autres,
# et se souvenir des échappatoires citées plus haut (\k, 'k', command k).
(( $+commands[kubectl] )) && alias k='kubectl'
(( $+commands[helm]    )) && alias h='helm'
(( $+commands[argocd]  )) && alias a='argocd'
