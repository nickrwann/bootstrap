#!/usr/bin/env bash
# wsl-setup.sh — Bootstrap the WSL (Ubuntu) environment.
# Run from inside WSL after setup.ps1 has completed on the Windows side.
#
# Usage:
#   git clone https://github.com/nickrwann/bootstrap ~/src/github.com/nickrwann/bootstrap
#   ~/src/github.com/nickrwann/bootstrap/wsl-setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "================================"
echo "  nickrwann/bootstrap (WSL)"
echo "================================"
echo ""

# ── 1. Install Starship ──────────────────────────────────────────────────────

echo "[1/2] Checking for Starship..."

if command -v starship &>/dev/null; then
    echo "  Starship already installed: $(starship --version | head -1)"
else
    echo "  Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    echo "  Starship installed."
fi

# ── 2. Install Zellij ────────────────────────────────────────────────────────

echo ""
echo "[2/2] Checking for Zellij..."

if command -v zellij &>/dev/null; then
    echo "  Zellij already installed: $(zellij --version)"
else
    echo "  Installing Zellij..."
    ZELLIJ_VERSION=$(curl -sL https://api.github.com/repos/zellij-org/zellij/releases/latest | grep '"tag_name"' | head -1 | sed 's/.*"v\(.*\)".*/\1/')
    ZELLIJ_URL="https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-x86_64-unknown-linux-musl.tar.gz"
    echo "  Downloading Zellij v${ZELLIJ_VERSION}..."
    curl -sL "$ZELLIJ_URL" | tar xz -C /tmp
    mkdir -p "$HOME/.local/bin"
    mv /tmp/zellij "$HOME/.local/bin/zellij"
    chmod +x "$HOME/.local/bin/zellij"
    echo "  Zellij installed to ~/.local/bin/zellij"
fi

# ── Link configs ─────────────────────────────────────────────────────────────

echo ""
echo "Linking configuration files..."

# Starship
mkdir -p "$HOME/.config"
ln -sf "$SCRIPT_DIR/config/starship.toml" "$HOME/.config/starship.toml"
echo "  ~/.config/starship.toml -> repo"

# Zellij
mkdir -p "$HOME/.config/zellij"
ln -sf "$SCRIPT_DIR/config/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"
echo "  ~/.config/zellij/config.kdl -> repo"

# Ensure starship init is in .bashrc
if ! grep -q 'starship init bash' "$HOME/.bashrc" 2>/dev/null; then
    echo '' >> "$HOME/.bashrc"
    echo '# Starship prompt' >> "$HOME/.bashrc"
    echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
    echo "  Added starship init to .bashrc"
fi

# Ensure ~/.local/bin is on PATH in .bashrc
if ! grep -q '\.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo '' >> "$HOME/.bashrc"
    echo '# Local binaries' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "  Added ~/.local/bin to PATH in .bashrc"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "================================"
echo "  WSL bootstrap complete."
echo "================================"
echo ""
echo "  Open a new terminal or run 'exec bash' to pick up changes."
echo ""
