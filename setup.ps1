# setup.ps1 — Bootstrap entry point
# Run from PowerShell:
#   irm https://raw.githubusercontent.com/nickrwann/bootstrap/main/setup.ps1 | iex

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "  nickrwann/bootstrap" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Verify winget is available ────────────────────────────────────────────

Write-Host "[1/2] Checking for winget..." -ForegroundColor Yellow

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
Write-Host "[2/2] Checking for Git..." -ForegroundColor Yellow

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

# ── Done ──────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "  Bootstrap complete." -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
