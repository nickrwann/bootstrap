# setup.ps1 — Bootstrap entry point
# Run from PowerShell (elevated):
#   irm https://raw.githubusercontent.com/nickrwann/bootstrap/main/setup.ps1 | iex
#
# Supports two phases:
#   Phase 1 (manual):  Windows tools + WSL install, registers auto-continue, reboots
#   Phase 2 (RunOnce): clones repo into WSL, runs wsl-setup.sh, cleans up

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Helpers ───────────────────────────────────────────────────────────────────

function Prompt-YesNo {
    param([string]$Question, [bool]$Default = $true)
    $hint = if ($Default) { "(Y/n)" } else { "(y/N)" }
    $answer = Read-Host "  $Question $hint"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
    return $answer.Trim().ToLower() -eq 'y'
}

function Refresh-Path {
    $env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' +
                [System.Environment]::GetEnvironmentVariable('PATH', 'User')
}

# ── Detect phase ──────────────────────────────────────────────────────────────

$repoUrl = "https://github.com/nickrwann/bootstrap.git"
$wslRepoDir = "~/src/github.com/nickrwann/bootstrap"
$phase2Flag = "$env:LOCALAPPDATA\bootstrap-phase2"

if (Test-Path $phase2Flag) {
    # ══════════════════════════════════════════════════════════════════════════
    # Phase 2 — runs automatically after reboot via RunOnce
    # ══════════════════════════════════════════════════════════════════════════
    Remove-Item $phase2Flag -Force

    Write-Host ""
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "  nickrwann/bootstrap (phase 2)" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""

    # Set Ubuntu 24.04 as default Windows Terminal profile
    Write-Host "Configuring Windows Terminal default profile..." -ForegroundColor Yellow
    $wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path $wtSettingsPath) {
        $settings = Get-Content $wtSettingsPath -Raw | ConvertFrom-Json
        $ubuntuProfile = $settings.profiles.list |
            Where-Object { $_.name -match 'Ubuntu 24' -or $_.source -match 'Ubuntu-24.04' } |
            Select-Object -First 1
        if ($ubuntuProfile) {
            $settings.defaultProfile = $ubuntuProfile.guid
            $settings | ConvertTo-Json -Depth 20 | Set-Content $wtSettingsPath -Encoding UTF8
            Write-Host "  Default profile set to Ubuntu 24.04." -ForegroundColor Green
        } else {
            Write-Host "  Ubuntu 24.04 profile not found in Windows Terminal." -ForegroundColor Yellow
        }
    }

    # Clone repo into WSL and run wsl-setup.sh
    Write-Host ""
    Write-Host "Setting up WSL environment..." -ForegroundColor Yellow

    wsl -d Ubuntu-24.04 -- bash -c "
        mkdir -p ~/src/github.com/nickrwann
        if [ ! -d $wslRepoDir ]; then
            git clone $repoUrl $wslRepoDir
        else
            cd $wslRepoDir && git pull
        fi
        bash $wslRepoDir/wsl-setup.sh
    "

    Write-Host ""
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "  Bootstrap complete!" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Open Windows Terminal to start in Ubuntu 24.04." -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "  Press Enter to close"
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# Phase 1 — interactive Windows setup
# ══════════════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "  nickrwann/bootstrap" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Verify winget ──────────────────────────────────────────────────────────

Write-Host "[prereq] Checking for winget..." -ForegroundColor Yellow

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "  winget not found." -ForegroundColor Red
    Write-Host "  Install 'App Installer' from the Microsoft Store, then re-run this script." -ForegroundColor Red
    Write-Host "  https://aka.ms/getwinget" -ForegroundColor DarkGray
    Write-Host ""
    exit 1
}

Write-Host "  winget found." -ForegroundColor Green
Write-Host ""

# ── 2. Git ────────────────────────────────────────────────────────────────────

if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "[Git] Already installed: $(git --version)" -ForegroundColor Green
} elseif (Prompt-YesNo "Install Git?") {
    Write-Host "  Installing Git via winget..." -ForegroundColor Yellow
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    Refresh-Path
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "  Git installed." -ForegroundColor Green
    } else {
        Write-Host "  Git installed — may need a new terminal session for PATH." -ForegroundColor Yellow
    }
} else {
    Write-Host "  Skipped Git." -ForegroundColor DarkGray
}

Write-Host ""

# ── 3. Windows Terminal ───────────────────────────────────────────────────────

$wtInstalled = winget list --id Microsoft.WindowsTerminal 2>$null | Select-String 'Microsoft.WindowsTerminal'
if ($wtInstalled) {
    Write-Host "[Windows Terminal] Already installed." -ForegroundColor Green
} elseif (Prompt-YesNo "Install Windows Terminal?") {
    Write-Host "  Installing Windows Terminal via winget..." -ForegroundColor Yellow
    winget install --id Microsoft.WindowsTerminal -e --source winget --accept-package-agreements --accept-source-agreements
    Write-Host "  Windows Terminal installed." -ForegroundColor Green
} else {
    Write-Host "  Skipped Windows Terminal." -ForegroundColor DarkGray
}

Write-Host ""

# ── 4. WSL + Ubuntu 24.04 ────────────────────────────────────────────────────

$needsReboot = $false

$wslDistros = wsl --list --quiet 2>$null
$ubuntuInstalled = $wslDistros | Where-Object { $_ -match 'Ubuntu-24.04' }

if ($ubuntuInstalled) {
    Write-Host "[WSL] Ubuntu 24.04 already installed." -ForegroundColor Green
} elseif (Prompt-YesNo "Install WSL + Ubuntu 24.04?") {
    Write-Host "  Installing WSL + Ubuntu 24.04 (pinned)..." -ForegroundColor Yellow
    wsl --install -d Ubuntu-24.04
    $needsReboot = $true
    Write-Host "  WSL + Ubuntu 24.04 installed." -ForegroundColor Green
} else {
    Write-Host "  Skipped WSL." -ForegroundColor DarkGray
}

Write-Host ""

# ── Register phase 2 and reboot (or run phase 2 now) ─────────────────────────

if ($needsReboot) {
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "  Phase 1 complete — reboot required." -ForegroundColor Yellow
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  After reboot, setup will continue automatically:" -ForegroundColor DarkGray
    Write-Host "    - Set Ubuntu 24.04 as default Terminal profile" -ForegroundColor DarkGray
    Write-Host "    - Clone bootstrap repo into WSL" -ForegroundColor DarkGray
    Write-Host "    - Install Starship + Zellij with configs" -ForegroundColor DarkGray
    Write-Host ""

    # Save the script locally so RunOnce can reference it
    $localScript = "$env:LOCALAPPDATA\bootstrap-setup.ps1"
    $scriptUrl = "https://raw.githubusercontent.com/nickrwann/bootstrap/main/setup.ps1"
    Invoke-WebRequest -Uri $scriptUrl -OutFile $localScript

    # Drop a flag so phase 2 knows to run
    New-Item -Path $phase2Flag -ItemType File -Force | Out-Null

    # Register RunOnce to continue after reboot
    $runCmd = "powershell.exe -ExecutionPolicy Bypass -File `"$localScript`""
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" `
                     -Name "BootstrapPhase2" `
                     -Value $runCmd

    if (Prompt-YesNo "Reboot now?") {
        Restart-Computer
    } else {
        Write-Host "  Reboot when you're ready — phase 2 will run automatically." -ForegroundColor DarkGray
    }
} else {
    # No reboot needed — run phase 2 inline
    Write-Host "No reboot needed. Continuing to WSL setup..." -ForegroundColor Yellow
    Write-Host ""

    # Set Ubuntu 24.04 as default Windows Terminal profile
    $wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path $wtSettingsPath) {
        $settings = Get-Content $wtSettingsPath -Raw | ConvertFrom-Json
        $ubuntuProfile = $settings.profiles.list |
            Where-Object { $_.name -match 'Ubuntu 24' -or $_.source -match 'Ubuntu-24.04' } |
            Select-Object -First 1
        if ($ubuntuProfile) {
            $settings.defaultProfile = $ubuntuProfile.guid
            $settings | ConvertTo-Json -Depth 20 | Set-Content $wtSettingsPath -Encoding UTF8
            Write-Host "  Default Terminal profile set to Ubuntu 24.04." -ForegroundColor Green
        }
    }

    # Clone repo into WSL and run wsl-setup.sh
    wsl -d Ubuntu-24.04 -- bash -c "
        mkdir -p ~/src/github.com/nickrwann
        if [ ! -d $wslRepoDir ]; then
            git clone $repoUrl $wslRepoDir
        else
            cd $wslRepoDir && git pull
        fi
        bash $wslRepoDir/wsl-setup.sh
    "

    Write-Host ""
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "  Bootstrap complete!" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""
}
