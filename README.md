# bootstrap

One-liner Windows dev machine setup. Paste into PowerShell, walk away, come back ready.

## Quick start

Open an **elevated PowerShell** and run:

```powershell
irm https://raw.githubusercontent.com/nickrwann/bootstrap/main/setup.ps1 | iex
```

That's it. The script handles everything in two phases:

### Phase 1 (before reboot)
You'll be prompted Y/N for each step:
- **Git** — via winget
- **Windows Terminal** — via winget
- **WSL + Ubuntu 24.04** — pinned distro

If WSL was just installed, the script registers a RunOnce task and reboots.

### Phase 2 (after reboot, automatic)
Picks up automatically on next login — no manual steps:
- Sets **Ubuntu 24.04 as the default Terminal profile**
- **Clones this repo** into WSL at `~/src/github.com/nickrwann/bootstrap`
- Runs `wsl-setup.sh` inside Ubuntu, which prompts Y/N for:
  - **Starship** (shell prompt)
  - **Zellij** (terminal multiplexer)
  - **Config symlinks** (Starship + Zellij configs from repo)

If WSL was already installed (no reboot needed), both phases run back-to-back in one go.

## What's in the box

```
setup.ps1              # Windows bootstrap (one-liner entry point, two-phase)
wsl-setup.sh           # WSL/Ubuntu bootstrap (interactive)
config/
  starship.toml        # Starship config (bracketed segments, full path)
  zellij/config.kdl    # Zellij config (Nord theme, custom keybinds)
```

## Requirements

- Windows 10 (1809+) or Windows 11
- [App Installer (winget)](https://aka.ms/getwinget) — comes pre-installed on most modern Windows machines

## Roadmap

- [ ] Dotfiles (bash, git)
- [ ] Dev tools (uv, gh, Docker, etc.)
- [ ] More winget apps (VS Code, Spotify, etc.)
