# bootstrap

One-liner Windows dev machine setup. Paste into PowerShell and go.

```powershell
irm https://raw.githubusercontent.com/nickrwann/bootstrap/main/setup.ps1 | iex
```

## What it does (right now)

1. Verifies `winget` is available
2. Installs `Git` via winget if it isn't already

More tools and an interactive installer are coming — this is the foundation.

## Requirements

- Windows 10 (1809+) or Windows 11
- [App Installer (winget)](https://aka.ms/getwinget) — comes pre-installed on most modern Windows machines

## Roadmap

- [ ] Interactive menu to pick what to install
- [ ] WSL setup
- [ ] Dotfiles
- [ ] Dev tools (languages, CLIs, apps)
