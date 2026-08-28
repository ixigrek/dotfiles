# FPATH/PATH sont exportés : sans -U, chaque shell imbriqué ré-empile les
# mêmes entrées. Attention, zsh n'applique l'unicité que sur le TABLEAU
# (path/fpath) : un `export PATH="x:$PATH"` la contourne, d'où la syntaxe
# tableau partout ci-dessous.
typeset -U path fpath

# Homebrew en premier : tout le reste en dépend (BREW_PREFIX, PATH...).
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

export HOMEBREW_NO_REQUIRE_TAP_TRUST=1

path=("$HOME/.local/bin" $path)
[ -d /opt/homebrew/opt/ffmpeg-full/bin ] && \
  path=(/opt/homebrew/opt/ffmpeg-full/bin $path)

# --- Go ---
export GOPATH="$HOME/go"
if command -v brew >/dev/null 2>&1 && brew --prefix golang >/dev/null 2>&1; then
  export GOROOT="$(brew --prefix golang)/libexec"
  path+=("$GOROOT/bin")
fi
path+=("$GOPATH/bin")
