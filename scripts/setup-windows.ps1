# Bee Cluster - Windows Machine Setup Script
# Run as Administrator in PowerShell:
# irm https://raw.githubusercontent.com/DaCoderMan/bee-claude-workspace/main/scripts/setup-windows.ps1 | iex

Write-Host "=== Bee Cluster Windows Setup ===" -ForegroundColor Cyan

# 1. Add VPS SSH pubkey to authorized_keys
Write-Host "Setting up SSH authorized_keys..." -ForegroundColor Yellow
$sshDir = "$env:USERPROFILE\.ssh"
$authKeys = "$sshDir\authorized_keys"
$vpsKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCYYc+sL2Jv2V8Ce80DA6ARVBxccsktxuKdQQoVFQaDuiTfLFZGe92OI9OzWDP7CkW9qjn3MEGK7A5CBW1JEofcP1/DLYtg7SZvk8w3v3QYBPflB1+uEx048DqJmGrgYB9wTib9Bhhc1H3P0cjQh7Cd4JNE+4L9qvAL0PCO9im98jDnQSERFbjyQWYwh0PNRhtDQiWlGH9bRqzN3r0bSp4aCjnCwwa23hExbmUmovI5fEXayMLlrvh29CNOzKp6wHhaDqnfq+xteKsQpavyfgu/ct18NdTUNOCaoVUoexxddqh07vIBIrCiipftEcDDnRmiAFBcmJ1S4GgOn0BFINcV36TB7WSpIG0Y6SBLXMqvg5/QCrAb1OLHDMR69VRY2gu+yNmfPVMsTZCBWHb0KJeRpnsQDP4yhi3zgzm8Ucr08CvyVtSOQQBU13DG2NF1hijkXcubQKHsD/eWz9kjM3YXFkJLCkgrO/S1bwlWHuq+53H+czuB60fmr1xUcs7oUZU5ZKHl/5y6ZdIU/jRTUW9cS1kGlf+K69R6ovnbqgpQYjVoQi8n8t3M5LH0bXVlgO8N1B2HMYsef14bQ94ctDNebrUe8Df857+ZLgAaqxaryty2lykVOdcaOThNmOzgWu/LQhw5C7wPCndyoyfNpadHPEimM0H/Y+qjA8q8octQ4Q== claude@workitulife-prod"

if (!(Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force | Out-Null }
if (!(Test-Path $authKeys)) { New-Item -ItemType File -Path $authKeys -Force | Out-Null }
$existing = Get-Content $authKeys -ErrorAction SilentlyContinue
if ($existing -notcontains $vpsKey) {
    Add-Content -Path $authKeys -Value $vpsKey
    Write-Host "VPS pubkey added to authorized_keys" -ForegroundColor Green
} else {
    Write-Host "VPS pubkey already present" -ForegroundColor Green
}

# 2. Enable OpenSSH Server
Write-Host "Enabling OpenSSH Server..." -ForegroundColor Yellow
$sshFeature = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
if ($sshFeature.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Write-Host "OpenSSH Server installed" -ForegroundColor Green
} else {
    Write-Host "OpenSSH Server already installed" -ForegroundColor Green
}
Set-Service -Name sshd -StartupType Automatic
Start-Service sshd -ErrorAction SilentlyContinue
Write-Host "sshd service started" -ForegroundColor Green

# Fix authorized_keys permissions for OpenSSH
icacls $authKeys /inheritance:r /grant "SYSTEM:(F)" /grant "Administrators:(F)" /grant "${env:USERNAME}:(F)" 2>$null

# 3. Create claude-workspace
Write-Host "Creating claude-workspace..." -ForegroundColor Yellow
$workspace = "$env:USERPROFILE\claude-workspace"
New-Item -ItemType Directory -Path $workspace -Force | Out-Null
New-Item -ItemType Directory -Path "$workspace\projects" -Force | Out-Null
New-Item -ItemType Directory -Path "$workspace\scripts" -Force | Out-Null
New-Item -ItemType Directory -Path "$workspace\temp" -Force | Out-Null
Write-Host "Workspace created at $workspace" -ForegroundColor Green

# 4. Check/Install Node.js
Write-Host "Checking Node.js..." -ForegroundColor Yellow
$nodeCheck = Get-Command node -ErrorAction SilentlyContinue
if (!$nodeCheck) {
    Write-Host "Installing Node.js via winget..." -ForegroundColor Yellow
    winget install -e --id OpenJS.NodeJS --silent --accept-package-agreements --accept-source-agreements
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
} else {
    Write-Host "Node.js already installed: $(node --version)" -ForegroundColor Green
}

# 5. Install Claude Code CLI
Write-Host "Installing Claude Code CLI..." -ForegroundColor Yellow
$claudeCheck = Get-Command claude -ErrorAction SilentlyContinue
if (!$claudeCheck) {
    npm install -g @anthropic-ai/claude-code
    Write-Host "Claude Code installed" -ForegroundColor Green
} else {
    Write-Host "Claude Code already installed: $(claude --version)" -ForegroundColor Green
}

# 6. Create bee-claude.bat wrapper
$batPath = "$env:USERPROFILE\claude-workspace\bee-claude.bat"
Set-Content -Path $batPath -Value "@echo off`r`nclaude --dangerously-skip-permissions %*"
# Add to PATH
$userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*claude-workspace*") {
    [System.Environment]::SetEnvironmentVariable("PATH", "$userPath;$workspace", "User")
}
Write-Host "bee-claude.bat created" -ForegroundColor Green

# 7. Clone/update workspace repo
Write-Host "Syncing workspace repo..." -ForegroundColor Yellow
$gitCheck = Get-Command git -ErrorAction SilentlyContinue
if ($gitCheck) {
    Set-Location $workspace
    if (Test-Path "$workspace\.git") {
        git pull 2>&1 | Out-Null
    } else {
        git clone https://github.com/DaCoderMan/bee-claude-workspace.git . 2>&1 | Out-Null
    }
    Write-Host "Workspace repo synced" -ForegroundColor Green
} else {
    Write-Host "git not found - install Git for Windows from git-scm.com" -ForegroundColor Yellow
}

# 8. Configure git identity
if ($gitCheck) {
    git config --global user.email "jonathanperlin@gmail.com"
    git config --global user.name "Yonatan Perlin"
}

# Done
Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "Machine: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "User: $env:USERNAME" -ForegroundColor White
Write-Host "Workspace: $workspace" -ForegroundColor White
Write-Host "SSH: enabled (VPS can now connect)" -ForegroundColor Green
Write-Host ""
Write-Host "Next: restart PowerShell, then run: claude --dangerously-skip-permissions" -ForegroundColor Yellow
