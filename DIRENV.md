# Sessions cloud par répertoire

Tutoriel du mécanisme `direnv` de ce dépôt : comment le contexte cloud
(gcloud, Azure, AWS) devient une propriété du répertoire courant, comment en
créer un, et comment le gérer au quotidien.

Résumé et table des fichiers : [README](README.md#contexte-cloud-par-répertoire-direnv).

---

## 1. Le problème

Les trois CLI cloud gardent un contexte **global**, partagé par tous les
terminaux et persistant entre les sessions :

- `gcloud config set project X` réécrit `~/.config/gcloud/configurations/config_default` ;
- `az account set -s X` réécrit `~/.azure/azureProfile.json` ;
- `aws configure set` réécrit `~/.aws/config`.

Deux conséquences. La première est un risque : on bascule sur la prod pour une
commande, on oublie de revenir, et le `terraform apply` du lendemain part sur
le mauvais projet. La seconde est que le prompt ne peut pas aider — un module
qui lit le contexte global affiche *toujours* quelque chose, y compris dans
`~`, où ça ne veut rien dire.

## 2. Le principe

Le contexte vit dans le dépôt, pas dans le shell.

```
cd ~/work/staging
  │
  └─ hook direnv (precmd + chpwd, posé par ~/.zsh/60-tools.zsh)
       │
       ├─ source ~/.config/direnv/direnvrc      → définit use gcloud|azure|aws
       └─ exécute ./.envrc                      → « use gcloud staging »
            │
            └─ export CLOUDSDK_ACTIVE_CONFIG_NAME=staging
                 ├─ la CLI gcloud lit cette variable en priorité
                 └─ starship ne rend [gcloud] que si elle existe

cd ~
  └─ direnv retire la variable → CLI neutre, prompt nu
```

Le prompt est donc le **miroir exact** du mécanisme, jamais une source
d'information indépendante : ce qu'il affiche est ce que la CLI utilisera.

| Provider | Variable exportée | Ce qui est cloisonné | Affiché par starship |
| --- | --- | --- | --- |
| gcloud | `CLOUDSDK_ACTIVE_CONFIG_NAME` | la configuration nommée : projet, compte, région. **Pas** les credentials, qui restent communs | le `project` |
| azure | `AZURE_CONFIG_DIR` | tout le répertoire de config, tokens compris | l'abonnement `isDefault` |
| aws | `AWS_PROFILE` (+ `AWS_REGION`) | rien : la variable est déjà propre au shell | la valeur brute de `AWS_PROFILE` |

Deux asymétries à garder en tête, elles expliquent la forme du code :

- **gcloud** aurait pu être cloisonné par `CLOUDSDK_CONFIG` (répertoire entier),
  mais ça isolerait aussi les tokens : un `gcloud auth login` par projet. On ne
  bascule donc que la configuration active, un seul login pour tout.
- **azure** n'a pas d'équivalent des configurations nommées, et son module
  starship ne connaît pas `detect_env_vars` : il lit toujours
  `$AZURE_CONFIG_DIR`, à défaut `~/.azure`. Sa neutralité hors projet ne vient
  pas d'un filtre d'affichage mais du **répertoire vide**
  `~/.azure-profiles/none` posé par `60-tools.zsh`. Ne pas y toucher sans
  toucher au module.

## 3. Prérequis, une fois par machine

```bash
brew install direnv        # le hook de 60-tools.zsh est conditionnel : sans direnv, rien ne se passe
gcloud auth login          # magasin de credentials commun à toutes les configurations
az login                   # alimente ~/.azure, la session de référence recopiée par `use azure`
aws login                  # CLI v2 : session navigateur, credentials dans ~/.aws/login/cache
```

Pour AWS, `aws login` est le chemin qui marche sur un compte isolé. `aws
configure sso` est réservé aux organisations ayant activé **IAM Identity
Center** : sa première question est l'URL du portail
(`https://d-xxxxxxxxxx.awsapps.com/start`), qui n'existe que dans ce cas — sans
Identity Center on reste bloqué sur ce prompt, sans rien à y entrer (cf. §6).

---

## 4. Tutoriel : un projet gcloud, de zéro

### Étape 1 — créer la configuration nommée

```bash
gcloud config configurations create staging --no-activate
```

`--no-activate` n'est pas optionnel : sans lui, la nouvelle configuration
devient l'active **globale** — exactement ce qu'on cherche à éviter — et la CLI
l'utilisera partout, y compris hors du projet.

### Étape 2 — la renseigner, avec la variable en préfixe

```bash
CLOUDSDK_ACTIVE_CONFIG_NAME=staging gcloud config set project staging-000000
CLOUDSDK_ACTIVE_CONFIG_NAME=staging gcloud config set account moi@example.com
CLOUDSDK_ACTIVE_CONFIG_NAME=staging gcloud config set compute/region europe-west1   # optionnel
```

Le préfixe n'est pas un tic de prudence, c'est l'ordre correct. `use gcloud`
**refuse** de charger une configuration sans `project` (sinon la CLI réclamerait
un projet à chaque commande, pendant que le prompt afficherait un symbole nu).
Écrire le `.envrc` d'abord ne marche donc pas : il échoue, la variable n'est pas
posée, et le `gcloud config set` qui suit atterrit dans `default`.

Une fois le `.envrc` en place (étape 3), le préfixe devient inutile : depuis le
dossier, `gcloud config set project ...` écrit dans la configuration du projet.

### Étape 3 — le `.envrc`

```bash
cd ~/work/staging
echo 'use gcloud staging' > .envrc
direnv allow
```

`direnv allow` est à rejouer **après chaque modification** du fichier : direnv
mémorise un hash, et refuse de charger un contenu qu'il n'a pas vu approuvé.

### Étape 4 — vérifier

```bash
echo $CLOUDSDK_ACTIVE_CONFIG_NAME   # staging
gcloud config list                  # project = staging-000000
cd .. && echo $CLOUDSDK_ACTIVE_CONFIG_NAME   # vide
```

Le prompt doit afficher `󱇶 staging-000000` dans le dossier, et rien dehors.

### Étape 5 — pour un dépôt d'infra : Terraform et les SDK

**Terraform et les bibliothèques clientes ne lisent pas la configuration
gcloud**, seulement l'environnement et les *Application Default Credentials*.
La configuration active ne les concerne pas. Ajouter au `.envrc` :

```bash
use gcloud staging
export GOOGLE_CLOUD_PROJECT=staging-000000
```

et, une fois : `gcloud auth application-default login`.

Les ADC sont globales
(`~/.config/gcloud/application_default_credentials.json`) et ne suivent pas la
configuration active. Avec plusieurs comptes, les cloisonner explicitement :

```bash
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/.adc/staging.json"
```

---

## 5. Tutoriel : un profil Azure

```bash
cd ~/work/staging
echo 'use azure staging' >> .envrc
direnv allow
```

Il n'y a rien à créer au préalable : au premier passage, `use azure` crée
`~/.azure-profiles/staging` et **recopie la session de `~/.azure`** (profil,
cache de tokens, service principals, config) pour éviter un `az login` de plus.
direnv l'annonce :

```
azure: profil 'staging' amorcé depuis /Users/simon/.azure — az account set -s <abonnement>
```

Ensuite le profil vit sa vie. Depuis le dossier :

```bash
az account list -o table
az account set -s "Abonnement Staging"
```

n'affecte que ce profil — `~/.azure` et les autres profils ne bougent pas.

Un abonnement visible dans le portail mais absent de `az account list` est
presque toujours un cache : `az login` fige la liste dans `azureProfile.json`,
et `az account list` la relit sans appel réseau. Un abonnement créé depuis, ou
un rôle accordé depuis, n'y figure pas. `--refresh` force le rappel de l'API :

```bash
az account list --refresh -o table
```

À rejouer **dans chaque profil** : `use azure` recopie `azureProfile.json` à
l'amorçage, donc un profil créé avant garde l'instantané périmé, et rafraîchir
`~/.azure` ne s'y propage pas. Depuis le dossier du projet, `AZURE_CONFIG_DIR`
est déjà posé — la commande vise le bon profil d'elle-même.

Hors projet, `AZURE_CONFIG_DIR` pointe sur `~/.azure-profiles/none`, un
répertoire vide : `az` n'a aucune session, et le prompt n'affiche rien. C'est
aussi là qu'atterrit un `az login` lancé hors projet, ce qui est sans
conséquence — `use azure` sait amorcer depuis `none` à défaut de `~/.azure`.

Pour consulter la session de référence ponctuellement, sans quitter le dossier :

```bash
AZURE_CONFIG_DIR=~/.azure az account show
```

---

## 6. Tutoriel : un profil AWS

Rien à cloisonner, `AWS_PROFILE` est déjà une variable par shell. Le profil doit
exister dans `~/.aws/config` (`use aws` le vérifie et refuse sinon) :

```bash
aws configure set region eu-west-3 --profile staging   # crée la section [profile staging]
aws login --profile staging                            # y attache une session
echo 'use aws staging eu-west-3' >> .envrc             # la région est optionnelle
direnv allow
```

Le `configure set` d'abord n'est pas décoratif : c'est lui qui écrit la section,
et `use aws` refuse un profil que `~/.aws/config` ne déclare pas.

Trois façons d'alimenter un profil, selon ce dont on dispose — `aws configure
sso` n'est **pas** le cas général, il suppose une organisation :

| Situation | Commande |
| --- | --- |
| Compte isolé, pas d'organisation | `aws login --profile staging` (CLI v2, session navigateur) |
| Organisation avec IAM Identity Center | `aws configure sso --profile staging` — demande la start URL du portail |
| Clés d'accès d'un utilisateur IAM | `aws configure --profile staging` |

**La frontière d'isolation d'AWS est le compte**, pas le projet (gcloud) ni
l'abonnement (Azure). Deux profils sur un même compte et une même identité
n'isolent donc rien : le prompt afficherait `staging` sans qu'aucun droit ne
change. Pour que le mécanisme ait ici la même valeur que chez les deux autres
providers, il faut soit un second compte, soit deux rôles IAM assumés depuis
celui-ci :

```ini
[profile staging]
role_arn = arn:aws:iam::000000000000:role/staging
source_profile = default
region = eu-west-3
```

La région, si elle est donnée, pose `AWS_REGION` **et** `AWS_DEFAULT_REGION` :
les SDK récents lisent la première, les plus anciens et l'AWS CLI v1 la seconde.

Vérifier :

```bash
aws sts get-caller-identity
```

---

## 7. Un `.envrc` ne sert pas qu'au cloud

Le même fichier porte tout ce qui doit valoir « dans ce dépôt seulement » :

```bash
use gcloud staging
export GOOGLE_CLOUD_PROJECT=staging-000000

export KUBECONFIG="$PWD/.kube/config"        # kubectl cloisonné, pas de contexte global
export TF_VAR_environment=staging
export TF_CLI_ARGS_plan="-lock-timeout=5m"
path_add PATH ./bin                          # outils du dépôt en tête de PATH

source_env_if_exists .envrc.local            # surcharges locales, non versionnées
```

Quelques fonctions utiles de la stdlib direnv (`direnv stdlib` les liste
toutes) : `dotenv_if_exists`, `env_vars_required`, `source_up` (hériter du
`.envrc` d'un dossier parent), `watch_file` (recharger quand un fichier change).

**Versionner ou non ?** Le `.envrc` ne contient que des *noms* (configuration,
profil, projet) : il a sa place dans le dépôt, c'est même l'intérêt — le
contexte suit le clone. Les secrets vont dans `.envrc.local`, ajouté au
`.gitignore`.

---

## 8. Gérer au quotidien

**Voir ce qui est actif** — le prompt le dit, mais en cas de doute :

```bash
env | grep -E 'CLOUDSDK_ACTIVE_CONFIG_NAME|AZURE_CONFIG_DIR|AWS_PROFILE|AWS_REGION'
direnv status            # .envrc trouvé, autorisé ou non, état du chargement
```

**Changer le contexte d'un projet existant** — depuis le dossier, la CLI écrit
au bon endroit, il n'y a rien d'autre à faire :

```bash
gcloud config set project autre-projet-000000   # le fichier est sous watch_file : direnv recharge
az account set -s "Autre abonnement"
```

Pour changer de *configuration* ou de *profil*, c'est le `.envrc` qu'on édite —
puis `direnv allow`.

**Recharger, suspendre, retirer :**

```bash
direnv reload            # rejouer le .envrc sans en sortir/rentrer
direnv deny              # révoquer l'autorisation : le dossier redevient neutre
direnv allow             # la rendre
rm .envrc && cd .        # retirer complètement
direnv prune             # purger les autorisations de .envrc disparus
```

**Lancer une commande dans le contexte d'un autre dossier, sans y aller :**

```bash
direnv exec ~/work/prod gcloud compute instances list
```

**Inventaire des contextes disponibles :**

```bash
gcloud config configurations list
ls ~/.azure-profiles
aws configure list-profiles
```

---

## 9. Déboguer

| Symptôme | Piste |
| --- | --- |
| Rien ne se charge en entrant dans le dossier | `direnv status` : le `.envrc` est-il autorisé ? Sinon `direnv allow`. Vérifier aussi que `direnv` est bien installé — le hook de `60-tools.zsh` est conditionnel et échoue en silence. |
| `use gcloud: configuration 'x' inconnue` | la configuration n'existe pas : `gcloud config configurations create x --no-activate`. |
| `use gcloud: configuration 'x' sans project` | garde-fou volontaire : `CLOUDSDK_ACTIVE_CONFIG_NAME=x gcloud config set project <projet>` (cf. étape 2). |
| `use aws: profil 'x' absent de ~/.aws/config` | le profil n'est pas déclaré ; attention, la section s'écrit `[profile x]` dans `config` mais `[x]` dans `credentials`. |
| Le contexte est bon mais le prompt n'affiche rien | la variable est-elle **exportée** ? Voir les pièges ci-dessous. Pour gcloud, vérifier que le module lit bien un `project` dans `~/.config/gcloud/configurations/config_<nom>`. |
| `az account list` n'affiche pas un abonnement pourtant visible dans le portail | liste figée au login : `az account list --refresh`, depuis le dossier du projet pour viser son profil (cf. §5). |
| `aws configure sso` bloque sur `SSO start URL` | il suppose IAM Identity Center. Sans organisation, `aws login --profile <profil>` (cf. §6). |
| Le prompt affiche un abonnement Azure partout | `AZURE_CONFIG_DIR` ne pointe plus sur le répertoire vide — un `export` traînant, ou `~/.azure-profiles/none` supprimé. |
| Une variable persiste après être sorti du dossier | elle a été posée à la main dans le shell, pas par direnv : direnv ne retire que ce qu'il a posé. |
| Voir ce que direnv exporte réellement | `direnv export zsh \| tr ';' '\n'` |

Un shell propre pour comparer : `NO_ZELLIJ=1 zsh -i`.

---

## 10. Pièges

- **`export` obligatoire.** `FOO=bar` dans un `.envrc` n'est qu'une variable
  bash locale ; direnv ne propage que ce qui est exporté.
- **Le `.envrc` s'exécute dans le bash de direnv, pas dans zsh.** Pas de
  syntaxe zsh, pas d'alias, pas de fonctions du `.zshrc`.
- **`direnv allow` après chaque édition**, sinon le fichier est ignoré (avec un
  avertissement facile à manquer dans le défilement).
- **`default` garde son projet.** Hors projet, la CLI gcloud continue de
  l'utiliser sans que le prompt l'indique — le filtre `detect_env_vars` ne porte
  que sur l'affichage. Pour que « hors projet = aucun contexte » vaille aussi
  côté CLI, une fois, hors d'un dossier de projet :
  ```bash
  gcloud config configurations activate default && gcloud config unset project
  ```
- **`gcloud config configurations activate` est global.** Ne jamais l'utiliser
  pour basculer sur un projet : c'est précisément ce que le mécanisme remplace.
- **Terraform et les SDK ignorent la configuration gcloud** (cf. étape 5). Une
  CLI qui pointe sur staging n'empêche pas un `terraform apply` de partir sur
  autre chose.
- **`gcloud auth login` écrit dans la configuration active.** Lancé depuis un
  dossier de projet, il rattache le compte à *sa* configuration — c'est la bonne
  façon d'associer un deuxième compte à un projet ; lancé depuis `~`, il modifie
  `default`. Un `gcloud config list` après coup lève le doute.
- **Les tokens Azure sont dupliqués par profil.** Un `az login` dans `~/.azure`
  ne rafraîchit pas les profils déjà amorcés ; en cas de token expiré, faire le
  `az login` depuis le dossier du projet. Même logique pour la liste des
  abonnements, qui est un cache par profil (cf. §5).
- **Un profil AWS n'isole rien à lui seul.** Sans second compte ni rôle distinct,
  c'est un libellé de prompt et rien d'autre (cf. §6).
