# bootstrap

One-liner Windows dev machine setup. Paste into PowerShell and go.

## Windows side

Open an **elevated PowerShell** and run:

```powershell
irm https://raw.githubusercontent.com/nickrwann/bootstrap/main/setup.ps1 | iex
```

This will:
1. Verify `winget` is available
2. Install **Git**
3. Install **Windows Terminal**
4. Install **WSL + Ubuntu 24.04** (pinned)
5. Set Ubuntu 24.04 as the default Terminal profile
6. Prompt for a reboot

## WSL side

After reboot, open Windows Terminal (drops into Ubuntu) and run:

```bash
git clone https://github.com/nickrwann/bootstrap ~/src/github.com/nickrwann/bootstrap
~/src/github.com/nickrwann/bootstrap/wsl-setup.sh
```

This will:
1. Install **Starship** (shell prompt)
2. Install **Zellij** (terminal multiplexer, latest release)
3. Symlink configs from the repo into `~/.config/`
4. Add Starship init + `~/.local/bin` to `.bashrc`

## What's in the box

```
setup.ps1              # Windows bootstrap (the one-liner target)
wsl-setup.sh           # WSL/Ubuntu bootstrap
config/
  starship.toml        # Starship prompt config (bracketed segments, full path)
  zellij/config.kdl    # Zellij config (Nord theme, custom keybinds)
```

## Requirements

- Windows 10 (1809+) or Windows 11
- [App Installer (winget)](https://aka.ms/getwinget) — comes pre-installed on most modern Windows machines

## Roadmap

- [ ] Interactive menu to pick what to install
- [ ] Dotfiles (bash, git)
- [ ] Dev tools (languages, CLIs, apps)
