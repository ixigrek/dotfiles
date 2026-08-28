# Outils externes : complétions bash-only et hooks de shell.
# Après 50-fzf-tab (compinit est déjà passé), avant le 90-zellij qui exec.

# --- Complétions bash ---
# terraform et packer ne génèrent pas de complétion zsh : HashiCorp livre un
# `complete -C` bash, que bashcompinit sait envelopper (~5 ms).
# Le reste des outils passe par des fichiers statiques dans ~/.zfunc
# (cf. ~/.zsh/bin/regen-completions), qui ne coûtent rien au démarrage.
if (( ! $+functions[bashcompinit] )); then
  autoload -Uz bashcompinit && bashcompinit
fi
for _c in terraform packer; do
  _b="$(command -v $_c)" && [ -n "$_b" ] && complete -o nospace -C "$_b" "$_c"
done
unset _c _b

# --- direnv ---
# Charge/décharge un .envrc à chaque cd : KUBECONFIG, AWS_PROFILE,
# ARM_SUBSCRIPTION_ID, TF_VAR_*, venv uv... par dépôt.
# Le hook s'accroche à precmd et chpwd, il ne touche à aucun keybinding.
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi
