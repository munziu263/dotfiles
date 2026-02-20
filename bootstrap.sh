#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔧 Munatsi's dotfiles bootstrap"
echo "================================"

# Check for stow
if ! command -v stow &> /dev/null; then
    echo "Installing stow..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install stow
    else
        sudo apt-get install -y stow
    fi
fi

# Check for neovim
if ! command -v nvim &> /dev/null; then
    echo "Installing neovim..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install neovim
    else
        sudo apt-get install -y neovim
    fi
fi

# Check for tmux
if ! command -v tmux &> /dev/null; then
    echo "Installing tmux..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install tmux
    else
        sudo apt-get install -y tmux
    fi
fi

# Check for starship
if ! command -v starship &> /dev/null; then
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
for dir in mvim tmux starship; do
    echo "  → $dir"
    stow -R "$dir"
done

# Source aliases
if ! grep -q 'source.*\.aliases' "$HOME/.zshrc" 2>/dev/null && \
   ! grep -q 'source.*\.aliases' "$HOME/.bashrc" 2>/dev/null; then
    echo ""
    echo "Add this to your .zshrc or .bashrc:"
    echo "  source ~/.aliases"
fi

# Link aliases file directly (not stow — it goes to $HOME)
ln -sf "$DOTFILES_DIR/shell/.aliases" "$HOME/.aliases"

echo ""
echo "✅ Done! Open a new terminal or run: source ~/.aliases"
echo ""
echo "Next steps:"
echo "  • tmux: press prefix + I to install plugins"
echo "  • nvim: run 'mvim' — Lazy will auto-install plugins on first launch"
