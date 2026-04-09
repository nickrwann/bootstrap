# bootstrap

One-liner Windows dev machine setup. Interactive, idempotent, and opinionated only about tooling — not configuration.

## Quick start

Open an **elevated PowerShell** and run:

```powershell
irm https://raw.githubusercontent.com/nickrwann/bootstrap/main/setup.ps1 | iex
```

The script walks you through everything — prompting Y/N for each tool so you install only what you want.

## How it works

The setup runs in two phases. If a reboot is needed (first-time WSL install), phase 2 picks up automatically on next login via a Windows RunOnce task. If WSL is already installed, both phases run back-to-back with no interruption.

### Phase 1 — Windows

| Tool | Install method |
|------|---------------|
| Git | winget |
| Windows Terminal | winget |
| uv | winget |
| VS Code | winget |
| GitHub Desktop | winget |
| Docker Desktop | winget |
| Spotify | winget |
| WSL + Ubuntu 24.04 | `wsl --install` (pinned) |

### Phase 2 — WSL (Ubuntu)

Automatically clones this repo into WSL, sets Ubuntu as the default Terminal profile, and runs the WSL setup.

| Category | Tools |
|----------|-------|
| Core CLI | `fzf`, `fd`, `ripgrep`, `jq`, `tree` |
| Dev platforms | `uv`, `gh`, `glab`, `docker`, `devin` |
| Terminal | `starship`, `zellij` |
| Configs | Starship + Zellij configs (symlinked from repo) |

Every step checks if the tool is already installed and skips it. Config linking detects existing symlinks and warns before overwriting.

## Requirements

- Windows 10 (1809+) or Windows 11
- [App Installer (winget)](https://aka.ms/getwinget) — pre-installed on most modern Windows
