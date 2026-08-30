# dotfiles

Config gérée par [chezmoi](https://chezmoi.io).

## Installation sur une machine neuve (macOS)

```bash
xcode-select --install
sudo -v
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply ixigrek
```

## Contexte cloud par répertoire (direnv)

Principe : le contexte cloud vit dans le dépôt, pas dans le shell. On entre
dans un dossier de projet, sa configuration gcloud / son profil Azure / son
profil AWS devient actif ; on en sort, plus aucun provider n'est actif — ni
pour les CLI, ni dans le prompt.

Le `.envrc` du dossier, autorisé une fois par `direnv allow` (et à nouveau
après chaque modification) :

```bash
use gcloud staging          # → CLOUDSDK_ACTIVE_CONFIG_NAME
use azure staging           # → AZURE_CONFIG_DIR
use aws staging eu-west-3   # → AWS_PROFILE, AWS_REGION (région optionnelle)
```

Trois fichiers y participent :

| Fichier | Rôle |
| --- | --- |
| `.zsh/60-tools.zsh` | accroche le hook direnv à `precmd`/`chpwd`, et pointe `AZURE_CONFIG_DIR` sur un répertoire vide par défaut |
| `.config/direnv/direnvrc` | fournit `use gcloud`, `use azure`, `use aws` |
| `.config/starship.toml` | n'affiche un provider que si la variable correspondante est posée |

**[DIRENV.md](DIRENV.md)** détaille le mécanisme et sert de tutoriel : création
d'un contexte pour chaque provider, gestion au quotidien, dépannage, pièges.
