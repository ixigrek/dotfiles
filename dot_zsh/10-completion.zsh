# fpath doit être complet AVANT le compinit lancé par oh-my-zsh (20-omz.zsh),
# sinon ~/.zfunc (_talosctl, _pass-cli) n'est pas indexé.
fpath=($HOME/.zfunc $fpath)
