#!/usr/bin/env bash
# One-shot setup for a fresh machine.
# curl -fsSL https://raw.githubusercontent.com/munziu263/dotfiles/main/setup.sh | bash
set -euo pipefail

echo "🚀 Setting up Munatsi's dev environment"
echo "========================================="

# Detect OS and package manager
if [[ "$OSTYPE" == "darwin"* ]]; then
    PKG="brew"
    # Install Homebrew if missing
    if ! command -v brew &>/dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
    fi
elif command -v dnf &>/dev/null; then
    PKG="dnf"
else
    PKG="apt"
fi

# Install core tools only
echo "Installing core tools..."
case "$PKG" in
    brew)
        brew install neovim tmux fzf stow bat git ripgrep
        ;;
    dnf)
        sudo dnf install -y neovim tmux fzf stow bat git ripgrep
        ;;
    apt)
        sudo apt-get update -qq
        sudo apt-get install -y neovim tmux fzf stow bat git ripgrep
        ;;
esac

# Clone dotfiles
if [ -d "$HOME/dotfiles" ]; then
    echo "~/dotfiles already exists, pulling latest..."
    cd ~/dotfiles && git pull
else
    echo "Cloning dotfiles..."
    git clone https://github.com/munziu263/dotfiles.git ~/dotfiles
fi

# Run bootstrap
cd ~/dotfiles
./bootstrap.sh

echo ""
echo "🎉 All done! Open a new terminal or run: source ~/.aliases"
