# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Nature du dépôt

Dotfiles macOS gérés par [chezmoi](https://chezmoi.io). Pas de build, pas de tests, pas de linter : les fichiers sont des sources chezmoi appliquées vers `$HOME`.

Convention de nommage chezmoi (le nom du fichier EST la déclaration) :

| Source | Cible | Sens |
|---|---|---|
| `dot_zshrc` | `~/.zshrc` | `dot_` → `.` |
| `dot_zsh/60-tools.zsh` | `~/.zsh/60-tools.zsh` | |
| `dot_config/starship.toml` | `~/.config/starship.toml` | |
| `dot_zsh/bin/executable_regen-completions` | `~/.zsh/bin/regen-completions` (mode +x) | `executable_` → bit exécutable |
| `run_onchange_after_10-install-packages.sh.tmpl` | — | script rejoué quand son hash change, après l'application des fichiers |

Renommer un fichier revient donc à changer sa destination ou ses permissions.

## Deux clones du même dépôt

- `~/.local/share/chezmoi` — la **source vivante** que chezmoi lit. `~/.config/chezmoi/chezmoi.toml` y active `autoCommit` et `autoPush` : tout `chezmoi edit` / `chezmoi add` commite et pousse tout seul.
- Ce répertoire (`~/Documents/Projects/dotfiles`) — un clone de travail du même remote (`ixigrek/dotfiles`).

Conséquence : une modification faite ici ne change **rien** sur la machine tant qu'elle n'est pas poussée puis récupérée côté source (`chezmoi update`, qui fait `git pull` + `chezmoi apply`). Et l'autoCommit de l'autre clone peut créer des commits divergents — vérifier l'état des deux avant de pousser.

Vérifier avant d'appliquer : `chezmoi diff`, puis `chezmoi apply -v`.

## Chaîne de démarrage du shell

`~/.zshrc` ne fait que sourcer `~/.zsh/*.zsh` dans l'ordre lexical. **Le préfixe numérique encode une dépendance réelle**, pas un rangement esthétique — l'en-tête de `dot_zshrc` documente chaque cran. À retenir avant de déplacer ou d'ajouter quoi que ce soit :

- `00-path` pose Homebrew et `typeset -U path fpath` — tout en dépend.
- `10-completion` doit remplir `fpath` **avant** le `compinit` que lance oh-my-zsh en `20-omz`.
- `30-plugins` charge fzf-tab en premier (il doit s'installer sur la complétion avant les autres wrappers de widgets).
- `40-theme` définit `LS_COLORS` / `FZF_DEFAULT_OPTS`, dont `50-fzf-tab` dépend.
- `90-zellij` fait un `exec zellij` : **rien ne s'exécute après**. Les ajouts locaux vont dans `~/.zsh/80-local.zsh`, jamais en `9x`.

Corollaire piège : les installeurs de complétion (`scw autocomplete install`, `terragrunt --install-autocomplete`) écrivent leur ligne en fin de `~/.zshrc`, donc après l'exec — elle est morte. Refuser l'installation automatique et passer par `~/.zfunc` (voir ci-dessous) ou par `60-tools.zsh`.

Deux plugins réécrivent les keybindings après coup et imposent de passer par leurs hooks :
- **zsh-vi-mode** diffère son init au premier prompt et repose tous les bindings → tout binding doit être empilé dans `zvm_after_init_commands` (l'ordre y compte : `enable-fzf-tab` avant les bindings fzf).
- **starship** enveloppe `zle-keymap-select`, que zvm repose ensuite → `zvm_after_select_vi_mode` force le `reset-prompt` (`70-prompt.zsh`).

`NO_ZELLIJ=1 zsh -i` donne un shell interactif sans zellij, utile pour déboguer.

## Complétions

Trois sources, dans cet ordre de priorité de `fpath` :
1. `~/.zfunc` — trous comblés à la main, généré par `~/.zsh/bin/regen-completions`.
2. `$(brew --prefix)/share/zsh/site-functions` — la majorité des outils, suivi automatiquement des versions de formules. **Ne pas y superposer de copies dans `~/.zfunc`** : elles se périment ; le script les purge activement.
3. `complete -C` via `bashcompinit` dans `60-tools.zsh` — pour terraform, packer, terragrunt, qui ne fournissent pas de zsh.

```bash
~/.zsh/bin/regen-completions --dry   # audit seul
~/.zsh/bin/regen-completions         # génère ce qui manque, purge le zcompdump
```

Après toute écriture dans `~/.zfunc`, purger `~/.zcompdump*` — oh-my-zsh ne revalide son dumpfile qu'une fois par jour.

## Paquets

`dot_Brewfile` → `~/.Brewfile`. Le hook `run_onchange_after_10-install-packages.sh.tmpl` embarque son sha256 en commentaire : **modifier le Brewfile suffit à déclencher `brew bundle` au prochain `chezmoi apply`**. Le script installe aussi Homebrew si absent et génère les complétions de `pass-cli` / `talosctl`.

## Cohérence visuelle

La palette **Gruvbox Material** est dupliquée à la main dans six endroits, sans source unique. Changer une couleur implique de les répercuter partout :

- `dot_zsh/40-theme.zsh` — tableau `GRUVBOX`, `FZF_DEFAULT_OPTS`, `LS_COLORS`, `EZA_COLORS`
- `dot_config/starship.toml` — `[palettes.gruvbox_material]`
- `dot_config/zellij/config.kdl` — codes hex en dur dans les alias `zjstatus-tabs` / `zjstatus-status`
- `dot_config/bat/themes/gruvbox-material-dark.tmTheme` — nécessite `bat cache --build` après modification
- `dot_config/nvim/lua/plugins/colorscheme.lua` (`gruvbox_material_background = "medium"`, d'où bg0 `#282828`)
- `dot_config/ghostty/config.ghostty` — les 16 couleurs ANSI écrites à la main. **Ne pas remettre `theme = Gruvbox Material`** : le thème du même nom livré avec ghostty vient d'un import iTerm2-color-schemes cassé et n'est pas Gruvbox Material (rouge `#ea6926` au lieu de `#ea6962`, vert `#c1d041`, bleu `#6da3ec`, cyan orange `#fe9d6e`, blanc `#ffffff`). Le décalage est invisible sur starship, eza et bat, qui émettent du truecolor codé en dur, et frappe tout ce qui passe par les 16 ANSI : git diff, grep, man, neovim hors truecolor.

Les glyphs Nerd Font de `dot_config/starship.toml` sont fragiles : ils vivent
dans le Private Use Area (`U+E000`–`U+F8FF` pour la plupart, `U+F0000`+ pour les
icônes Material Design) et un éditeur ou un pipeline qui normalise l'UTF-8 les
remplace silencieusement par rien — le fichier reste valide, `symbol = " "` ne
contient plus qu'une espace et le prompt affiche un vide parfait. Ne pas les
retaper à la main : les reprendre de `starship preset nerd-font-symbols`, puis
vérifier qu'aucun n'est vide.

```bash
python3 -c "
import re
s = open('dot_config/starship.toml', encoding='utf-8').read()
print([(m[0], m[1]) for m in re.findall(r'^(symbol|ssh_symbol|read_only)\\s*=\\s*\"(.*)\"', s, re.M)
       if not any(0xE000 <= ord(c) <= 0xF8FF or ord(c) >= 0xF0000 for c in m[1])])
"   # seul [fill] doit ressortir : son symbole EST une espace
```

Contrainte transverse : ghostty tourne en `background-opacity 0.25` + `macos-glass-regular`. **Aucun fond opaque** dans le prompt, les barres zjstatus ou fzf (`bg:-1`, pas de `bg=` dans les formats zjstatus, pas de segments powerline) — sinon le blur casse.

## Contexte cloud par répertoire

`dot_config/direnv/direnvrc` fournit `use gcloud|azure|aws`, qui cloisonnent le contexte cloud par dépôt via variables d'environnement (`CLOUDSDK_ACTIVE_CONFIG_NAME`, `AZURE_CONFIG_DIR`, `AWS_PROFILE`). Le prompt starship est le miroir de ce mécanisme : les modules `gcloud`, `azure` et `env_var.aws` ne rendent quelque chose que si la variable correspondante existe. Les deux fichiers se lisent ensemble — modifier l'un sans l'autre casse le filtrage (le module `azure` en particulier n'a pas de `detect_env_vars` : sa neutralité repose sur le répertoire vide posé par `60-tools.zsh`).

## Zellij

`config.kdl` a `keybinds clear-defaults=true` et réserve en `shared_except "locked"` les combinaisons `Ctrl-p/n/h/s/b/o/g/q/t`. Ces touches **ne remontent jamais au shell** — c'est pourquoi fzf est bindé sur `Ctrl-F` et non sur son `Ctrl-T` par défaut. Vérifier ce fichier avant d'ajouter un keybinding zsh.

`layouts/default.kdl` et `layouts/default.swap.kdl` décrivent la même structure (barres zjstatus haut/bas) et doivent rester synchronisés : sans le swap layout, ouvrir un pane découpe le pane courant au lieu de réagencer l'onglet.

## Neovim

`dot_config/nvim` est un starter [LazyVim](https://lazyvim.github.io) : y ajouter des plugins dans `lua/plugins/*.lua`, les options dans `lua/config/`. `lazy-lock.json` fige les versions (`:Lazy update` pour le régénérer). `lua/plugins/example.lua` est le fichier d'exemple LazyVim, désactivé.

## Style

Les commentaires du dépôt sont en français et expliquent le **pourquoi** (contraintes d'ordre, pièges d'outils, alternatives écartées et leur raison), pas le quoi. Suivre cette densité : la plupart des lignes de ces fichiers existent pour contourner un comportement précis d'un outil, et le retirer ou le réordonner sans lire le commentaire casse quelque chose.
