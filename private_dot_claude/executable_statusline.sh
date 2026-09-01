#!/bin/bash
# Statusline Claude Code. Lit le JSON de session sur stdin, le traduit en
# variables d'environnement, et laisse starship faire le rendu avec
# ~/.claude/statusline.toml — même moteur et même palette que le prompt du
# shell (~/.config/starship.toml), donc rien de la logique de prompt n'est
# réécrit ici.
#
# Contrat : une seule ligne sur stdout, sans saut de ligne final, et toujours
# exit 0. Une statusline cassée ne doit pas casser la TUI.

set -u

input=$(cat)

# Repli si l'outillage manque : mieux vaut une ligne pauvre que rien.
tilde='~'

if ! command -v jq >/dev/null 2>&1; then
  printf '%s' "${PWD/#$HOME/$tilde}"
  exit 0
fi

# Séparateur US (0x1f) et non tabulation : IFS traite la tabulation comme du
# blanc, donc fusionne les séparateurs consécutifs et fait disparaître les
# champs vides — un `output_style` absent décalerait tous les champs suivants.
IFS=$'\x1f' read -r dir model style cost added removed exceeds transcript < <(
  jq -r '[
    (.workspace.current_dir // .cwd // ""),
    (.model.display_name // ""),
    (.output_style.name // ""),
    (.cost.total_cost_usd // 0),
    (.cost.total_lines_added // 0),
    (.cost.total_lines_removed // 0),
    (.exceeds_200k_tokens // false),
    (.transcript_path // "")
  ] | map(tostring) | join("\u001f")' <<<"$input" 2>/dev/null
)
dir=${dir:-$PWD}

if ! command -v starship >/dev/null 2>&1; then
  printf '%s%s' "${dir/#$HOME/$tilde}" "${model:+  ✳ $model}"
  exit 0
fi

[ -n "$model" ] && export CLAUDE_MODEL="$model"

# `default` est le cas normal : il ne mérite pas de place à l'écran.
[ -n "$style" ] && [ "$style" != "default" ] && export CLAUDE_STYLE="$style"

# awk plutôt que bash pour les comparaisons : cost est un flottant.
if [ -n "$cost" ] && awk -v c="$cost" 'BEGIN{exit !(c > 0)}' 2>/dev/null; then
  export CLAUDE_COST=$(printf '%.2f' "$cost")
fi

[ "${added:-0}" -gt 0 ] 2>/dev/null && export CLAUDE_ADDED="+$added"
[ "${removed:-0}" -gt 0 ] 2>/dev/null && export CLAUDE_REMOVED="-$removed"

# Occupation de la fenêtre de contexte. Le JSON ne porte que le booléen
# exceeds_200k_tokens, pas de compteur : le chiffre vient du transcript, sur le
# dernier message assistant de la session principale (isSidechain écarte les
# sous-agents, dont l'usage n'est pas celui de cette fenêtre).
#   contexte = input + cache_creation + cache_read
# tail borne le travail à chaque rafraîchissement : pas de relecture du fichier
# entier, qui grossit tout au long de la session.
if [ -n "$transcript" ] && [ -r "$transcript" ]; then
  tokens=$(tail -n 200 "$transcript" 2>/dev/null | jq -s '
    map(select(.type == "assistant" and .isSidechain != true and .message.usage != null))
    | last | if . == null then empty else
        (.message.usage | (.input_tokens // 0)
                        + (.cache_creation_input_tokens // 0)
                        + (.cache_read_input_tokens // 0))
      end' 2>/dev/null)

  if [ -n "${tokens:-}" ] && [ "$tokens" -gt 0 ] 2>/dev/null; then
    pct=$(( tokens * 100 / 200000 ))
    # Une variable par palier : un module env_var n'a qu'un style fixe, et
    # starship ne réinterprète pas le balisage contenu dans une valeur.
    if [ "$exceeds" = "true" ] || [ "$pct" -ge 80 ]; then
      export CLAUDE_CTX_HOT="$(( tokens / 1000 ))k ${pct}%"
    elif [ "$pct" -ge 50 ]; then
      export CLAUDE_CTX_WARN="$(( tokens / 1000 ))k ${pct}%"
    else
      export CLAUDE_CTX_OK="$(( tokens / 1000 ))k ${pct}%"
    fi
  fi
fi

# STARSHIP_SHELL vidée : héritée du zsh appelant, elle ferait émettre à
# starship les échappements de prompt zsh (%{...%}), que la TUI afficherait
# tels quels.
exec env STARSHIP_SHELL= STARSHIP_CONFIG="$HOME/.claude/statusline.toml" PWD="$dir" \
  starship prompt --path "$dir" --logical-path "$dir"
