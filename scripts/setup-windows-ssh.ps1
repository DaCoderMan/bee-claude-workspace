# Bee Cluster - Windows Machine Setup Script
# Run as Administrator on bee-1 and sparta-1
# Usage: powershell -ExecutionPolicy Bypass -File setup-windows-ssh.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== Bee Cluster: Windows Machine Setup ===" -ForegroundColor Cyan

# 1. Install OpenSSH Server if not present
Write-Host "`n[1/6] Checking OpenSSH Server..." -ForegroundColor Yellow
$sshServer = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
if ($sshServer.State -ne 'Installed') {
    Write-Host "Installing OpenSSH Server..."
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Write-Host "OpenSSH Server installed." -ForegroundColor Green
} else {
    Write-Host "OpenSSH Server already installed." -ForegroundColor Green
}

# Start and enable SSH service
Write-Host "Starting sshd service..."
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
Write-Host "sshd is running and set to auto-start." -ForegroundColor Green

# 2. Configure SSH authorized_keys
Write-Host "`n[2/6] Setting up SSH authorized_keys..." -ForegroundColor Yellow
$vpsPublicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCYYc+sL2Jv2V8Ce80DA6ARVBxccsktxuKdQQoVFQaDuiTfLFZGe92OI9OzWDP7CkW9qjn3MEGK7A5CBW1JEofcP1/DLYtg7SZvk8w3v3QYBPflB1+uEx048DqJmGrgYB9wTib9Bhhc1H3P0cjQh7Cd4JNE+4L9qvAL0PCO9im98jDnQSERFbjyQWYwh0PNRhtDQiWlGH9bRqzN3r0bSp4aCjnCwwa23hExbmUmovI5fEXayMLlrvh29CNOzKp6wHhaDqnfq+xteKsQpavyfgu/ct18NdTUNOCaoVUoexxddqh07vIBIrCiipftEcDDnRmiAFBcmJ1S4GgOn0BFINcV36TB7WSpIG0Y6SBLXMqvg5/QCrAb1OLHDMR69VRY2gu+yNmfPVMsTZCBWHb0KJeRpnsQDP4yhi3zgzm8Ucr08CvyVtSOQQBU13DG2NF1hijkXcubQKHsD/eWz9kjM3YXFkJLCkgrO/S1bwlWHuq+53H+czuB60fmr1xUcs7oUZU5ZKHl/5y6ZdIU/jRTUW9cS1kGlf+K69R6ovnbqgpQYjVoQi8n8t3M5LH0bXVlgO8N1B2HMYsef14bQ94ctDNebrUe8Df857+ZLgAaqxaryty2lykVOdcaOThNmOzgWu/LQhw5C7wPCndyoyfNpadHPEimM0H/Y+qjA8q8octQ4Q== claude@workitulife-prod"

$sshDir = "$env:USERPROFILE\.ssh"
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}

$authKeysFile = "$sshDir\authorized_keys"
$keyExists = $false
if (Test-Path $authKeysFile) {
    $existingKeys = Get-Content $authKeysFile -Raw
    if ($existingKeys -match "claude@workitulife-prod") {
        $keyExists = $true
        Write-Host "VPS key already in authorized_keys." -ForegroundColor Green
    }
}

if (-not $keyExists) {
    Add-Content -Path $authKeysFile -Value $vpsPublicKey
    Write-Host "VPS public key added to authorized_keys." -ForegroundColor Green
}

# Fix permissions for administrators_authorized_keys (Windows OpenSSH quirk)
$adminAuthKeys = "C:\ProgramData\ssh\administrators_authorized_keys"
if (Test-Path "C:\ProgramData\ssh") {
    Copy-Item $authKeysFile $adminAuthKeys -Force
    # Set proper ACL
    icacls $adminAuthKeys /inheritance:r /grant "SYSTEM:(F)" /grant "Administrators:(F)" | Out-Null
    Write-Host "Admin authorized_keys configured." -ForegroundColor Green
}

# 3. Install Node.js and Claude CLI
Write-Host "`n[3/6] Checking Node.js and Claude CLI..." -ForegroundColor Yellow
$nodeInstalled = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeInstalled) {
    Write-Host "Node.js not found. Installing via winget..."
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    Write-Host "Node.js installed. You may need to restart the terminal." -ForegroundColor Yellow
} else {
    Write-Host "Node.js $(node --version) found." -ForegroundColor Green
}

Write-Host "Installing Claude CLI..."
npm install -g @anthropic-ai/claude-code 2>$null
Write-Host "Claude CLI installed." -ForegroundColor Green

# 4. Create workspace directory
Write-Host "`n[4/6] Setting up claude-workspace..." -ForegroundColor Yellow
$workspaceDir = "$env:USERPROFILE\claude-workspace"
if (-not (Test-Path $workspaceDir)) {
    New-Item -ItemType Directory -Path $workspaceDir -Force | Out-Null
}

# 5. Clone repository
Write-Host "`n[5/6] Cloning bee-claude-workspace..." -ForegroundColor Yellow
$repoDir = "$workspaceDir\bee-claude-workspace"
if (-not (Test-Path $repoDir)) {
    Set-Location $workspaceDir
    git clone https://github.com/DaCoderMan/bee-claude-workspace.git 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Git clone failed. Make sure git is installed and you have access." -ForegroundColor Red
    } else {
        Write-Host "Repository cloned." -ForegroundColor Green
    }
} else {
    Write-Host "Repository already exists, pulling latest..." -ForegroundColor Yellow
    Set-Location $repoDir
    git pull 2>$null
}

# 6. Create bee-claude.bat wrapper
Write-Host "`n[6/6] Creating bee-claude.bat wrapper..." -ForegroundColor Yellow
$batContent = @"
@echo off
REM Bee Claude Workspace Launcher
REM Runs Claude CLI in the bee workspace with full permissions

cd /d "%USERPROFILE%\claude-workspace\bee-claude-workspace"
claude --dangerously-skip-permissions %*
"@
$batPath = "$env:USERPROFILE\claude-workspace\bee-claude.bat"
Set-Content -Path $batPath -Value $batContent
Write-Host "Created $batPath" -ForegroundColor Green

# Add to PATH if not already there
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*claude-workspace*") {
    [System.Environment]::SetEnvironmentVariable("PATH", "$currentPath;$env:USERPROFILE\claude-workspace", "User")
    Write-Host "Added claude-workspace to PATH." -ForegroundColor Green
}

Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "Next steps:"
Write-Host "  1. Test SSH from VPS: ssh $env:USERNAME@<tailscale-ip>"
Write-Host "  2. Test Claude: bee-claude 'hello'"
Write-Host "  3. Verify Tailscale: tailscale status"
