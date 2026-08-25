# dotfiles

Config gérée par [chezmoi](https://chezmoi.io).

## Installation sur une machine neuve (macOS)

```bash
xcode-select --install
sudo -v
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply ixigrek
```
