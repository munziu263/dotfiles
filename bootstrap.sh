#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔧 Munatsi's dotfiles bootstrap"
echo "================================"

# Detect package manager
if [[ "$OSTYPE" == "darwin"* ]]; then
    PKG_INSTALL="brew install"
elif command -v dnf &>/dev/null; then
    PKG_INSTALL="sudo dnf install -y"
else
    PKG_INSTALL="sudo apt-get install -y"
fi

# Check for stow
if ! command -v stow &> /dev/null; then
    echo "Installing stow..."
    $PKG_INSTALL stow
fi

# Check for neovim
if ! command -v nvim &> /dev/null; then
    echo "Installing neovim..."
    $PKG_INSTALL neovim
fi

# Check for tmux
if ! command -v tmux &> /dev/null; then
    echo "Installing tmux..."
    $PKG_INSTALL tmux
fi

# Check for starship (macOS only)
if [[ "$OSTYPE" == "darwin"* ]] && ! command -v starship &> /dev/null; then
    echo "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Install TPM (Tmux Plugin Manager)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Stow everything
echo ""
echo "Linking dotfiles..."
cd "$DOTFILES_DIR"

# Core packages (all machines)
for dir in mvim tmux claude-plugins; do
    echo "  → $dir"
    stow -R "$dir"
done

# Starship (macOS only -- remote uses default prompt or installs separately)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  → starship"
    stow -R starship
fi

# Ghostty (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  → ghostty"
    stow -R ghostty
fi

# Link aliases file directly (not stow — it goes to $HOME)
ln -sf "$DOTFILES_DIR/shell/.aliases" "$HOME/.aliases"

# Source aliases
if ! grep -q 'for f in ~/.aliases' "$HOME/.zshrc" 2>/dev/null && \
   ! grep -q 'for f in ~/.aliases' "$HOME/.bashrc" 2>/dev/null; then
    echo ""
    echo "Add this to your .zshrc or .bashrc:"
    echo '  for f in ~/.aliases ~/.aliases.*; do [ -f "$f" ] && source "$f"; done'
fi

echo ""
echo "✅ Done! Open a new terminal or run: source ~/.aliases"
echo ""
echo "Next steps:"
echo "  • tmux: press prefix + I to install plugins"
echo "  • nvim: run 'mvim' — Lazy will auto-install plugins on first launch"
echo "  • skills: npx skills add mattpocock/skills grill-me"
