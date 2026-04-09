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

# ══════════════════════════════════════════════════════════════════════════════
# Core CLI tools (apt) — used by agents and everyday dev work
# ══════════════════════════════════════════════════════════════════════════════

echo "── Core CLI tools ──"
echo ""

# Batch apt tools: only prompt for ones not already installed
apt_tools=()
apt_labels=()

declare -A apt_map=(
    [fzf]="fzf"
    [fd-find]="fd"
    [ripgrep]="ripgrep"
    [jq]="jq"
    [tree]="tree"
)

declare -A apt_desc=(
    [fzf]="fzf (fuzzy finder)"
    [fd-find]="fd (fast file finder)"
    [ripgrep]="ripgrep (fast grep)"
    [jq]="jq (JSON processor)"
    [tree]="tree (directory viewer)"
)

# fd and rg have different binary names than package names
declare -A apt_cmd=(
    [fzf]="fzf"
    [fd-find]="fdfind"
    [ripgrep]="rg"
    [jq]="jq"
    [tree]="tree"
)

for pkg in fzf fd-find ripgrep jq tree; do
    cmd="${apt_cmd[$pkg]}"
    desc="${apt_desc[$pkg]}"
    if command -v "$cmd" &>/dev/null; then
        echo "[$desc] Already installed."
    elif prompt_yn "Install $desc?"; then
        apt_tools+=("$pkg")
    else
        echo "  Skipped $desc."
    fi
done

if [ ${#apt_tools[@]} -gt 0 ]; then
    echo ""
    echo "  Installing: ${apt_tools[*]}..."
    sudo apt update -qq
    sudo apt install -y "${apt_tools[@]}"
    echo "  Done."
fi

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# Dev platforms — individual installs
# ══════════════════════════════════════════════════════════════════════════════

echo "── Dev platforms ──"
echo ""

# ── uv (Python toolchain) ────────────────────────────────────────────────────

if command -v uv &>/dev/null; then
    echo "[uv] Already installed: $(uv --version)"
elif prompt_yn "Install uv (Python toolchain)?"; then
    echo "  Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "  uv installed."
else
    echo "  Skipped uv."
fi

echo ""

# ── gh (GitHub CLI) ──────────────────────────────────────────────────────────

if command -v gh &>/dev/null; then
    echo "[gh] Already installed: $(gh --version | head -1)"
elif prompt_yn "Install gh (GitHub CLI)?"; then
    echo "  Installing gh..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt update -qq
    sudo apt install -y gh
    echo "  gh installed."
else
    echo "  Skipped gh."
fi

echo ""

# ── glab (GitLab CLI) ────────────────────────────────────────────────────────

if command -v glab &>/dev/null; then
    echo "[glab] Already installed: $(glab --version | head -1)"
elif prompt_yn "Install glab (GitLab CLI)?"; then
    echo "  Installing glab..."
    GLAB_VERSION=$(curl -sL https://api.github.com/repos/gitlab-org/cli/releases/latest | grep '"tag_name"' | head -1 | sed 's/.*"v\(.*\)".*/\1/')
    GLAB_URL="https://github.com/gitlab-org/cli/releases/download/v${GLAB_VERSION}/glab_${GLAB_VERSION}_linux_amd64.tar.gz"
    curl -sL "$GLAB_URL" | tar xz -C /tmp
    mv /tmp/bin/glab "$HOME/.local/bin/glab"
    chmod +x "$HOME/.local/bin/glab"
    echo "  glab installed to ~/.local/bin/glab"
else
    echo "  Skipped glab."
fi

echo ""

# ── Docker ────────────────────────────────────────────────────────────────────

if command -v docker &>/dev/null; then
    echo "[Docker] Already installed: $(docker --version)"
elif prompt_yn "Install Docker?"; then
    echo "  Installing Docker..."
    sudo apt update -qq
    docker_packages=(docker.io)
    if apt-cache show docker-buildx-plugin &>/dev/null; then
        docker_packages+=(docker-buildx-plugin)
    fi
    if apt-cache show docker-compose-plugin &>/dev/null; then
        docker_packages+=(docker-compose-plugin)
    else
        docker_packages+=(docker-compose)
    fi
    sudo apt install -y "${docker_packages[@]}"
    if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
        sudo usermod -aG docker "$USER" || true
    fi
    echo "  Docker installed. Log out and back in for group membership."
else
    echo "  Skipped Docker."
fi

echo ""

# ── Devin CLI ─────────────────────────────────────────────────────────────────

if command -v devin &>/dev/null; then
    echo "[Devin] Already installed: $(devin --version | head -1)"
elif prompt_yn "Install Devin CLI?"; then
    echo "  Installing Devin CLI..."
    curl -fsSL https://cli.devin.ai/install.sh | sh
    echo "  Devin installed."
else
    echo "  Skipped Devin."
fi

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# Terminal tools
# ══════════════════════════════════════════════════════════════════════════════

echo "── Terminal tools ──"
echo ""

# ── Starship ──────────────────────────────────────────────────────────────────

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

# ── Zellij ────────────────────────────────────────────────────────────────────

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

# ══════════════════════════════════════════════════════════════════════════════
# Configs
# ══════════════════════════════════════════════════════════════════════════════

echo "── Configs ──"
echo ""

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
