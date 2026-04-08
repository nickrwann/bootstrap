# setup.ps1 — Bootstrap entry point
# Run from PowerShell (elevated):
#   irm https://raw.githubusercontent.com/nickrwann/bootstrap/main/setup.ps1 | iex

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "  nickrwann/bootstrap" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Verify winget is available ────────────────────────────────────────────

Write-Host "[1/4] Checking for winget..." -ForegroundColor Yellow

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "  winget not found." -ForegroundColor Red
    Write-Host "  Install 'App Installer' from the Microsoft Store, then re-run this script." -ForegroundColor Red
    Write-Host "  https://aka.ms/getwinget" -ForegroundColor DarkGray
    Write-Host ""
    exit 1
}

Write-Host "  winget found." -ForegroundColor Green

# ── 2. Install Git if missing ─────────────────────────────────────────────────

Write-Host ""
Write-Host "[2/4] Checking for Git..." -ForegroundColor Yellow

if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitVersion = git --version
    Write-Host "  Git already installed: $gitVersion" -ForegroundColor Green
} else {
    Write-Host "  Git not found. Installing via winget..." -ForegroundColor Yellow
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    # Refresh PATH so git is available in this session
    $env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' +
                [System.Environment]::GetEnvironmentVariable('PATH', 'User')
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "  Git installed successfully." -ForegroundColor Green
    } else {
        Write-Host "  Git installation may require a new terminal session to take effect." -ForegroundColor Yellow
    }
}

# ── 3. Install Windows Terminal ───────────────────────────────────────────────

Write-Host ""
Write-Host "[3/4] Checking for Windows Terminal..." -ForegroundColor Yellow

$wtInstalled = winget list --id Microsoft.WindowsTerminal 2>$null | Select-String 'Microsoft.WindowsTerminal'
if ($wtInstalled) {
    Write-Host "  Windows Terminal already installed." -ForegroundColor Green
} else {
    Write-Host "  Installing Windows Terminal via winget..." -ForegroundColor Yellow
    winget install --id Microsoft.WindowsTerminal -e --source winget --accept-package-agreements --accept-source-agreements
    Write-Host "  Windows Terminal installed." -ForegroundColor Green
}

# ── 4. Install WSL + Ubuntu 24.04 ─────────────────────────────────────────────

Write-Host ""
Write-Host "[4/4] Checking for WSL + Ubuntu 24.04..." -ForegroundColor Yellow

$wslDistros = wsl --list --quiet 2>$null
$ubuntuInstalled = $wslDistros | Where-Object { $_ -match 'Ubuntu-24.04' }

if ($ubuntuInstalled) {
    Write-Host "  Ubuntu 24.04 already installed." -ForegroundColor Green
} else {
    Write-Host "  Installing WSL + Ubuntu 24.04 (pinned)..." -ForegroundColor Yellow
    wsl --install -d Ubuntu-24.04
    Write-Host "  WSL + Ubuntu 24.04 installed." -ForegroundColor Green
}

# ── Configure Windows Terminal: set Ubuntu 24.04 as default profile ───────────

Write-Host ""
Write-Host "Configuring Windows Terminal default profile..." -ForegroundColor Yellow

$wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $wtSettingsPath) {
    $settings = Get-Content $wtSettingsPath -Raw | ConvertFrom-Json

    # Find the Ubuntu-24.04 profile by name
    $ubuntuProfile = $settings.profiles.list | Where-Object { $_.name -match 'Ubuntu 24' -or $_.source -match 'Ubuntu-24.04' } | Select-Object -First 1

    if ($ubuntuProfile) {
        $settings.defaultProfile = $ubuntuProfile.guid
        $settings | ConvertTo-Json -Depth 20 | Set-Content $wtSettingsPath -Encoding UTF8
        Write-Host "  Default profile set to Ubuntu 24.04." -ForegroundColor Green
    } else {
        Write-Host "  Ubuntu 24.04 profile not found in Windows Terminal yet." -ForegroundColor Yellow
        Write-Host "  Re-run this script after the reboot to apply the default profile." -ForegroundColor DarkGray
    }
} else {
    Write-Host "  Windows Terminal settings not found yet — will apply after reboot." -ForegroundColor Yellow
}

# ── Done — reboot required ────────────────────────────────────────────────────

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "  Bootstrap complete." -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  A reboot is required to finish WSL setup." -ForegroundColor Yellow
Write-Host "  After rebooting, open Windows Terminal — it will drop you into Ubuntu 24.04." -ForegroundColor DarkGray
Write-Host ""

$reboot = Read-Host "  Reboot now? (y/n)"
if ($reboot -eq 'y') {
    Restart-Computer
}
