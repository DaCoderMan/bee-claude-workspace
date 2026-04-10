#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Bee Cluster — Windows machine setup for bee-1 / sparta-1
.DESCRIPTION
    Sets up OpenSSH server, adds VPS pubkey, installs Node.js,
    Claude Code CLI, and clones the workspace repo.
    Run as Administrator on each Windows machine.
#>

param(
    [string]$VpsPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBwFCMGSGNSgmuJqesSloYSxNpgPPZVVZig39bVPFRJ5 claude@hive"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Bee Cluster Windows Setup ===" -ForegroundColor Cyan

# --- 1. Install OpenSSH Server ---
Write-Host "`n[1/6] Installing OpenSSH Server..." -ForegroundColor Yellow
$sshCap = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
if ($sshCap.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'
    Write-Host "  OpenSSH Server installed." -ForegroundColor Green
} else {
    Write-Host "  OpenSSH Server already installed." -ForegroundColor Green
}

# Start and enable sshd
Set-Service -Name sshd -StartupType Automatic
Start-Service sshd
Write-Host "  sshd service started and set to auto-start." -ForegroundColor Green

# --- 2. Add VPS SSH public key ---
Write-Host "`n[2/6] Adding VPS SSH public key..." -ForegroundColor Yellow
$authKeysDir = "$env:ProgramData\ssh"
$authKeysFile = "$authKeysDir\administrators_authorized_keys"

if (!(Test-Path $authKeysDir)) {
    New-Item -ItemType Directory -Path $authKeysDir -Force | Out-Null
}

if (!(Test-Path $authKeysFile) -or !(Select-String -Path $authKeysFile -Pattern $VpsPubKey -Quiet)) {
    Add-Content -Path $authKeysFile -Value $VpsPubKey
    # Fix permissions — only SYSTEM and Administrators
    icacls $authKeysFile /inheritance:r /grant "SYSTEM:(F)" /grant "BUILTIN\Administrators:(F)" | Out-Null
    Write-Host "  VPS pubkey added to $authKeysFile" -ForegroundColor Green
} else {
    Write-Host "  VPS pubkey already present." -ForegroundColor Green
}

# --- 3. Create C:\claude-workspace ---
Write-Host "`n[3/6] Creating C:\claude-workspace..." -ForegroundColor Yellow
if (!(Test-Path "C:\claude-workspace")) {
    New-Item -ItemType Directory -Path "C:\claude-workspace" -Force | Out-Null
    Write-Host "  Created C:\claude-workspace" -ForegroundColor Green
} else {
    Write-Host "  C:\claude-workspace already exists." -ForegroundColor Green
}

# --- 4. Install Node.js via winget ---
Write-Host "`n[4/6] Checking Node.js..." -ForegroundColor Yellow
$nodeInstalled = $false
try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "  Node.js $nodeVersion already installed." -ForegroundColor Green
        $nodeInstalled = $true
    }
} catch {}

if (!$nodeInstalled) {
    Write-Host "  Installing Node.js LTS via winget..." -ForegroundColor Yellow
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Host "  Node.js installed. You may need to restart your terminal." -ForegroundColor Green
}

# --- 5. Install Claude Code CLI ---
Write-Host "`n[5/6] Installing Claude Code CLI..." -ForegroundColor Yellow
try {
    $claudeVersion = npm list -g @anthropic-ai/claude-code 2>$null
    if ($claudeVersion -match "claude-code") {
        Write-Host "  Claude Code already installed globally." -ForegroundColor Green
    } else {
        throw "not installed"
    }
} catch {
    npm install -g @anthropic-ai/claude-code
    Write-Host "  Claude Code CLI installed." -ForegroundColor Green
}

# Create bee-claude.bat launcher
$batPath = "C:\claude-workspace\bee-claude.bat"
$batContent = "@echo off`r`nclaude --dangerously-skip-permissions %*"
Set-Content -Path $batPath -Value $batContent -Encoding ASCII
Write-Host "  Created $batPath" -ForegroundColor Green

# --- 6. Clone workspace repo ---
Write-Host "`n[6/6] Cloning workspace repo..." -ForegroundColor Yellow
if (!(Test-Path "C:\claude-workspace\.git")) {
    Push-Location "C:\claude-workspace"
    git clone https://github.com/DaCoderMan/claude-workspace.git .
    Pop-Location
    Write-Host "  Repo cloned to C:\claude-workspace" -ForegroundColor Green
} else {
    Push-Location "C:\claude-workspace"
    git pull origin main
    Pop-Location
    Write-Host "  Repo already cloned, pulled latest." -ForegroundColor Green
}

Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "Next steps:"
Write-Host "  1. Test SSH from VPS: ssh <username>@<tailscale-ip>"
Write-Host "  2. Run: C:\claude-workspace\bee-claude.bat"
Write-Host "  3. Set ANTHROPIC_API_KEY environment variable"
