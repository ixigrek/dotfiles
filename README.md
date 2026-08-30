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

Trois fichiers y participent :

| Fichier | Rôle |
| --- | --- |
| `.zsh/60-tools.zsh` | accroche le hook direnv à `precmd`/`chpwd`, et pointe `AZURE_CONFIG_DIR` sur un répertoire vide par défaut |
| `.config/direnv/direnvrc` | fournit `use gcloud`, `use azure`, `use aws` |
| `.config/starship.toml` | n'affiche un provider que si la variable correspondante est posée |

Chaque `.envrc` doit être autorisé une fois — et à nouveau après chaque
modification :

```bash
direnv allow
```

### gcloud

La configuration nommée porte le projet, le compte et la région ; le magasin
de credentials, lui, reste commun (un seul `gcloud auth login` pour toutes).

```bash
gcloud config configurations create staging --no-activate
```

`--no-activate` n'est pas optionnel : sans lui, la nouvelle configuration
devient l'active **globale**, et la CLI l'utilise partout, y compris hors
projet.

`.envrc` du dossier :

```bash
use gcloud staging
```

Puis, depuis le dossier une fois le `.envrc` chargé — `gcloud config set`
écrit alors dans la configuration du projet, pas dans `default` :

```bash
gcloud config set project staging-000000
gcloud config set account moi@example.com
gcloud config set compute/region europe-west1   # optionnel
```

`use gcloud` bascule via `CLOUDSDK_ACTIVE_CONFIG_NAME`, variable propre au
shell — contrairement à `gcloud config configurations activate`, qui est
global. Le fichier de configuration est sous `watch_file` : un
`gcloud config set project` suffit à faire recharger direnv.

**Terraform et les SDK ne lisent pas la configuration gcloud**, seulement
l'environnement et les ADC. Pour un dépôt d'infra, ajouter au `.envrc` :

```bash
export GOOGLE_CLOUD_PROJECT=staging-000000
```

et, une fois, `gcloud auth application-default login`. Les ADC sont globales
(`~/.config/gcloud/application_default_credentials.json`) et ne suivent pas la
configuration active : avec plusieurs comptes, pointer
`GOOGLE_APPLICATION_CREDENTIALS` sur un fichier dédié dans le `.envrc`.

### azure

`az` n'a pas d'équivalent des configurations nommées : le seul cloisonnement
possible est un répertoire de config par profil, tokens compris
(`~/.azure-profiles/<profil>`).

```bash
use azure staging
```

Le premier passage recopie la session de `~/.azure` pour éviter un `az login`
de plus ; ensuite le profil vit sa vie (`az account set -s <abonnement>`
n'affecte que lui). Hors projet, `AZURE_CONFIG_DIR` pointe sur un répertoire
vide : le module azure de starship n'a rien à afficher. Pour consulter la
session de référence ponctuellement : `AZURE_CONFIG_DIR=~/.azure az account show`.

### aws

`AWS_PROFILE` est déjà une variable par shell, il suffit de la poser. Le profil
doit exister dans `~/.aws/config`.

```bash
use aws staging eu-west-3   # la région est optionnelle
```

### Pièges

- **`export` obligatoire.** `FOO=bar` dans un `.envrc` n'est qu'une variable
  bash locale : direnv ne la propage pas.
- **Configuration gcloud vide.** `use gcloud` refuse de charger une
  configuration sans `project` — sinon gcloud réclamerait un projet à chaque
  commande et le prompt afficherait un symbole nu. Le `.envrc` ayant échoué,
  `CLOUDSDK_ACTIVE_CONFIG_NAME` n'est pas posée : le réglage se fait avec la
  variable en préfixe, `CLOUDSDK_ACTIVE_CONFIG_NAME=<cfg> gcloud config set
  project <projet>`.
- **`default` garde son projet.** Hors projet, la CLI continue de l'utiliser
  sans que le prompt l'indique. Pour que « hors projet = aucun contexte » vaille
  aussi côté CLI : `gcloud config unset project`, lancé hors d'un dossier de
  projet.
