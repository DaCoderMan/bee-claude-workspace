# Bee Cluster - Windows Machine Setup
# Run as Administrator: irm https://raw.githubusercontent.com/DaCoderMan/bee-claude-workspace/main/scripts/setup-windows.ps1 | iex

Write-Host "=== Bee Cluster Windows Setup ===" -ForegroundColor Cyan

# 1. SSH authorized_keys
$sshDir = "$env:USERPROFILE\.ssh"
$authKeys = "$sshDir\authorized_keys"
$beeIdKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLPlKgGLLl8LUKPqSiTzGTdXs82re/ihQvXegZowkf/ vps-claude-to-bee-20260329"
$rsaKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCYYc+sL2Jv2V8Ce80DA6ARVBxccsktxuKdQQoVFQaDuiTfLFZGe92OI9OzWDP7CkW9qjn3MEGK7A5CBW1JEofcP1/DLYtg7SZvk8w3v3QYBPflB1+uEx048DqJmGrgYB9wTib9Bhhc1H3P0cjQh7Cd4JNE+4L9qvAL0PCO9im98jDnQSERFbjyQWYwh0PNRhtDQiWlGH9bRqzN3r0bSp4aCjnCwwa23hExbmUmovI5fEXayMLlrvh29CNOzKp6wHhaDqnfq+xteKsQpavyfgu/ct18NdTUNOCaoVUoexxddqh07vIBIrCiipftEcDDnRmiAFBcmJ1S4GgOn0BFINcV36TB7WSpIG0Y6SBLXMqvg5/QCrAb1OLHDMR69VRY2gu+yNmfPVMsTZCBWHb0KJeRpnsQDP4yhi3zgzm8Ucr08CvyVtSOQQBU13DG2NF1hijkXcubQKHsD/eWz9kjM3YXFkJLCkgrO/S1bwlWHuq+53H+czuB60fmr1xUcs7oUZU5ZKHl/5y6ZdIU/jRTUW9cS1kGlf+K69R6ovnbqgpQYjVoQi8n8t3M5LH0bXVlgO8N1B2HMYsef14bQ94ctDNebrUe8Df857+ZLgAaqxaryty2lykVOdcaOThNmOzgWu/LQhw5C7wPCndyoyfNpadHPEimM0H/Y+qjA8q8octQ4Q== claude@workitulife-prod"
$vpsKeys = @($beeIdKey, $rsaKey)
Write-Host "Setting up SSH..." -ForegroundColor Yellow
if (!(Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force | Out-Null }
if (!(Test-Path $authKeys)) { New-Item -ItemType File -Path $authKeys -Force | Out-Null }
$existing = Get-Content $authKeys -ErrorAction SilentlyContinue
foreach ($key in $vpsKeys) { if ($existing -notcontains $key) { Add-Content -Path $authKeys -Value $key } }
icacls $authKeys /inheritance:r /grant "SYSTEM:(F)" /grant "Administrators:(F)" /grant "${env:USERNAME}:(F)" 2>$null
Write-Host "VPS pubkey added" -ForegroundColor Green

# 2. Enable OpenSSH Server
Write-Host "Enabling OpenSSH Server..." -ForegroundColor Yellow
$cap = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
if ($cap.State -ne 'Installed') { Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 }
Set-Service -Name sshd -StartupType Automatic
Start-Service sshd -ErrorAction SilentlyContinue
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -ErrorAction SilentlyContinue | Out-Null
Write-Host "OpenSSH Server running" -ForegroundColor Green

# 3. Workspace directory
$workspace = "$env:USERPROFILE\claude-workspace"
New-Item -ItemType Directory -Path "$workspace\projects","$workspace\scripts","$workspace\temp","$workspace\logs" -Force | Out-Null
Write-Host "Workspace: $workspace" -ForegroundColor Green

# 4. Node.js
if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Node.js..." -ForegroundColor Yellow
    winget install -e --id OpenJS.NodeJS --silent --accept-package-agreements --accept-source-agreements
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
} else { Write-Host "Node.js: $(node --version)" -ForegroundColor Green }

# 5. Claude Code CLI
if (!(Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Claude Code..." -ForegroundColor Yellow
    npm install -g @anthropic-ai/claude-code
} else { Write-Host "Claude: $(claude --version 2>&1 | Select-Object -First 1)" -ForegroundColor Green }

# 6. bee-claude.bat wrapper
Set-Content -Path "$workspace\bee-claude.bat" -Value "@echo off`r`nclaude --dangerously-skip-permissions %*"
$userPath = [System.Environment]::GetEnvironmentVariable("PATH","User")
if ($userPath -notlike "*claude-workspace*") {
    [System.Environment]::SetEnvironmentVariable("PATH","$userPath;$workspace","User")
}
Write-Host "bee-claude.bat created" -ForegroundColor Green

# 7. Git + repo
git config --global user.email "jonathanperlin@gmail.com"
git config --global user.name "Yonatan Perlin"
if (Get-Command git -ErrorAction SilentlyContinue) {
    Set-Location $workspace
    if (Test-Path "$workspace\.git") { git pull 2>&1 | Out-Null }
    else { git clone https://github.com/DaCoderMan/bee-claude-workspace.git . 2>&1 | Out-Null }
    Write-Host "Workspace repo synced" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== DONE: $env:COMPUTERNAME ===" -ForegroundColor Cyan
Write-Host "SSH enabled - VPS can now connect via Tailscale" -ForegroundColor Green
Write-Host "Restart PowerShell then run: claude --dangerously-skip-permissions" -ForegroundColor Yellow
