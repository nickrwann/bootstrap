#!/usr/bin/env bash
# wsl-setup.sh — Bootstrap the WSL (Ubuntu) environment.
# Called automatically by setup.ps1 phase 2, or run manually.
#
# Usage:
#   ~/src/github.com/nickrwann/bootstrap/wsl-setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Helpers ───────────────────────────────────────────────────────────────────

prompt_yn() {
    local question="$1"
    local default="${2:-y}"
    local hint
    if [ "$default" = "y" ]; then hint="(Y/n)"; else hint="(y/N)"; fi
    printf "  %s %s " "$question" "$hint"
    read -r answer
    answer="${answer:-$default}"
    [ "${answer,,}" = "y" ]
}

echo ""
echo "================================"
echo "  nickrwann/bootstrap (WSL)"
echo "================================"
echo ""

# ── 1. Starship ──────────────────────────────────────────────────────────────

if command -v starship &>/dev/null; then
    echo "[Starship] Already installed: $(starship --version | head -1)"
elif prompt_yn "Install Starship (shell prompt)?"; then
    echo "  Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    echo "  Starship installed."
else
    echo "  Skipped Starship."
fi

echo ""

# ── 2. Zellij ─────────────────────────────────────────────────────────────────

if command -v zellij &>/dev/null; then
    echo "[Zellij] Already installed: $(zellij --version)"
elif prompt_yn "Install Zellij (terminal multiplexer)?"; then
    echo "  Installing Zellij..."
    ZELLIJ_VERSION=$(curl -sL https://api.github.com/repos/zellij-org/zellij/releases/latest | grep '"tag_name"' | head -1 | sed 's/.*"v\(.*\)".*/\1/')
    ZELLIJ_URL="https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-x86_64-unknown-linux-musl.tar.gz"
    echo "  Downloading Zellij v${ZELLIJ_VERSION}..."
    curl -sL "$ZELLIJ_URL" | tar xz -C /tmp
    mkdir -p "$HOME/.local/bin"
    mv /tmp/zellij "$HOME/.local/bin/zellij"
    chmod +x "$HOME/.local/bin/zellij"
    echo "  Zellij installed to ~/.local/bin/zellij"
else
    echo "  Skipped Zellij."
fi

echo ""

# ── 3. Link configs ──────────────────────────────────────────────────────────

# Helper: check if a path is already symlinked to the expected repo target
is_linked_to_repo() {
    local link="$1" target="$2"
    [ -L "$link" ] && [ "$(readlink -f "$link")" = "$(readlink -f "$target")" ]
}

# Starship config
STARSHIP_LINK="$HOME/.config/starship.toml"
STARSHIP_TARGET="$SCRIPT_DIR/config/starship.toml"
if is_linked_to_repo "$STARSHIP_LINK" "$STARSHIP_TARGET"; then
    echo "[Starship config] Already linked to repo."
elif [ -e "$STARSHIP_LINK" ]; then
    if prompt_yn "Starship config exists. Overwrite with repo version?" "n"; then
        mkdir -p "$HOME/.config"
        ln -sf "$STARSHIP_TARGET" "$STARSHIP_LINK"
        echo "  ~/.config/starship.toml -> repo (overwritten)"
    else
        echo "  Kept existing Starship config."
    fi
elif prompt_yn "Link Starship config from repo?"; then
    mkdir -p "$HOME/.config"
    ln -sf "$STARSHIP_TARGET" "$STARSHIP_LINK"
    echo "  ~/.config/starship.toml -> repo"
else
    echo "  Skipped Starship config."
fi

echo ""

# Zellij config
ZELLIJ_LINK="$HOME/.config/zellij/config.kdl"
ZELLIJ_TARGET="$SCRIPT_DIR/config/zellij/config.kdl"
if is_linked_to_repo "$ZELLIJ_LINK" "$ZELLIJ_TARGET"; then
    echo "[Zellij config] Already linked to repo."
elif [ -e "$ZELLIJ_LINK" ]; then
    if prompt_yn "Zellij config exists. Overwrite with repo version?" "n"; then
        mkdir -p "$HOME/.config/zellij"
        ln -sf "$ZELLIJ_TARGET" "$ZELLIJ_LINK"
        echo "  ~/.config/zellij/config.kdl -> repo (overwritten)"
    else
        echo "  Kept existing Zellij config."
    fi
elif prompt_yn "Link Zellij config from repo?"; then
    mkdir -p "$HOME/.config/zellij"
    ln -sf "$ZELLIJ_TARGET" "$ZELLIJ_LINK"
    echo "  ~/.config/zellij/config.kdl -> repo"
else
    echo "  Skipped Zellij config."
fi

echo ""

# ── Shell integration ─────────────────────────────────────────────────────────

# Ensure ~/.local/bin is on PATH in .bashrc
if ! grep -q '\.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo '' >> "$HOME/.bashrc"
    echo '# Local binaries' >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "  Added ~/.local/bin to PATH in .bashrc"
fi

# Ensure starship init is in .bashrc (only if starship is installed)
if command -v starship &>/dev/null; then
    if ! grep -q 'starship init bash' "$HOME/.bashrc" 2>/dev/null; then
        echo '' >> "$HOME/.bashrc"
        echo '# Starship prompt' >> "$HOME/.bashrc"
        echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
        echo "  Added starship init to .bashrc"
    fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "================================"
echo "  WSL bootstrap complete."
echo "================================"
echo ""
echo "  Open a new terminal or run 'exec bash' to pick up changes."
echo ""
