#!/usr/bin/env bash
# profile-deps.sh — lazy dependency installer for neovim profiles
# Called by profile aliases before launching nvim.
# Each profile has a deps file at ~/.config/<profile>/deps.txt
#
# deps.txt format (one per line):
#   brew:package        — install via brew
#   pip:package         — install via pip/pipx
#   npm:package         — install via npm -g
#   cargo:package       — install via cargo
#
# Skips anything already installed. Fast no-op on subsequent runs.

set -euo pipefail

PROFILE="$1"
DEPS_FILE="$HOME/.config/$PROFILE/deps.txt"

if [[ ! -f "$DEPS_FILE" ]]; then
    exit 0
fi

# Track if we installed anything (for messaging)
installed=0

while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip comments and blank lines
    [[ -z "$line" || "$line" == \#* ]] && continue

    manager="${line%%:*}"
    package="${line#*:}"

    case "$manager" in
        brew)
            if ! brew list "$package" &>/dev/null; then
                echo "📦 Installing $package via brew..."
                brew install "$package"
                installed=$((installed + 1))
            fi
            ;;
        pip)
            if ! command -v "$package" &>/dev/null; then
                echo "📦 Installing $package via pipx..."
                pipx install "$package" 2>/dev/null || pip install --user "$package"
                installed=$((installed + 1))
            fi
            ;;
        npm)
            if ! npm list -g "$package" &>/dev/null 2>&1; then
                echo "📦 Installing $package via npm..."
                npm install -g "$package"
                installed=$((installed + 1))
            fi
            ;;
        cargo)
            if ! command -v "$package" &>/dev/null; then
                echo "📦 Installing $package via cargo..."
                cargo install "$package"
                installed=$((installed + 1))
            fi
            ;;
        *)
            echo "⚠️  Unknown manager: $manager (for $package)"
            ;;
    esac
done < "$DEPS_FILE"

if [[ $installed -gt 0 ]]; then
    echo "✅ Installed $installed dependencies for $PROFILE"
fi
