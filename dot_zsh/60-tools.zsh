# Outils externes : complétions bash-only et hooks de shell.
# Après 50-fzf-tab (compinit est déjà passé), avant le 90-zellij qui exec.

# --- Complétions bash ---
# terraform, packer et terragrunt ne génèrent pas de complétion zsh : ils
# livrent un `complete -C` bash, que bashcompinit sait envelopper (~5 ms).
# (`terragrunt --install-autocomplete` écrirait cette ligne en fin de .zshrc,
# donc APRÈS l'exec de 90-zellij : elle ne s'exécuterait jamais.)
# Le reste des outils passe par des fichiers statiques dans ~/.zfunc
# (cf. ~/.zsh/bin/regen-completions), qui ne coûtent rien au démarrage.
if (( ! $+functions[bashcompinit] )); then
  autoload -Uz bashcompinit && bashcompinit
fi
for _c in terraform packer terragrunt; do
  _b="$(command -v $_c)" && [ -n "$_b" ] && complete -o nospace -C "$_b" "$_c"
done
unset _c _b

# --- gcloud ---
# Le cask dépose `completion.zsh.inc` dans les site-functions de brew sous le
# nom `_google_cloud_sdk`, mais ce n'est pas une fonction autoloadable : c'est
# un script à sourcer, que compinit n'exécute donc jamais. On le source ici
# (il pose lui-même le `complete -F` de gcloud, gsutil et bq, ~0 ms).
_gc=/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc
[ -r "$_gc" ] && source "$_gc"
unset _gc

# --- direnv ---
# Charge/décharge un .envrc à chaque cd : KUBECONFIG, AWS_PROFILE,
# ARM_SUBSCRIPTION_ID, TF_VAR_*, venv uv... par dépôt.
# Le hook s'accroche à precmd et chpwd, il ne touche à aucun keybinding.
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# --- zoxide ---
# `z <fragment>` saute vers le répertoire le plus fréquenté qui correspond,
# `zi` ouvre la sélection dans fzf — donc avec FZF_DEFAULT_OPTS (40-theme.zsh).
# Ce sont des commandes, pas des keybindings : ni zellij ni zsh-vi-mode ne
# sont concernés. Ajoute un hook chpwd, à côté de celui de direnv.
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi
