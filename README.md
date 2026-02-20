# dotfiles

My development environment. Neovim profiles + tmux + starship.

## Quick Start

```bash
git clone https://github.com/munziu263/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

## What's Inside

| Package | What |
|---------|------|
| `mvim` | Neovim config — Lazy.nvim, Catppuccin Mocha, Telescope, Treesitter, LSP |
| `tmux` | tmux config — vim-tmux-navigator, Catppuccin, sessionx, OSC 52 clipboard |
| `starship` | Starship prompt — Catppuccin Mocha palette |
| `shell` | Shell aliases for Neovim profiles |

## Neovim Profiles

Uses `NVIM_APPNAME` to run multiple independent configs:

```bash
mvim          # Main config (daily driver)
# pvim        # Python (pyright, ruff, debugpy) — coming soon
# tvim        # TypeScript (ts_ls, prettier) — coming soon
```

Each profile is a full standalone config at `~/.config/<name>/`.

## Structure

Uses [GNU Stow](https://www.gnu.org/software/stow/) for symlink management:

```
dotfiles/
├── mvim/.config/mvim/      → ~/.config/mvim/
├── tmux/.config/tmux/      → ~/.config/tmux/
├── starship/.config/       → ~/.config/starship.toml
├── shell/.aliases          → ~/.aliases
└── bootstrap.sh
```

## Adding a New Neovim Profile

1. Copy `mvim` as a starting point: `cp -r mvim pvim`
2. Rename the inner dir: `mv pvim/.config/{mvim,pvim}`
3. Customize plugins for your language
4. Add alias to `shell/.aliases`: `alias pvim='NVIM_APPNAME=pvim nvim'`
5. `stow pvim`
