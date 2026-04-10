# Windows Machine Setup — Manual Steps

## Prerequisites
- Windows 10/11 with admin access
- Tailscale installed and connected to tailnet
- Internet connection

## Automated Setup
Run PowerShell as Administrator:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\setup-windows.ps1
```

## Manual Steps (if script fails)

### 1. Enable OpenSSH Server
```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Set-Service -Name sshd -StartupType Automatic
Start-Service sshd
```

### 2. Add VPS SSH Key
Add the VPS public key to `C:\ProgramData\ssh\administrators_authorized_keys`:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBwFCMGSGNSgmuJqesSloYSxNpgPPZVVZig39bVPFRJ5 claude@hive
```
Then fix permissions:
```powershell
icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant "SYSTEM:(F)" /grant "BUILTIN\Administrators:(F)"
```

### 3. Install Node.js
```powershell
winget install OpenJS.NodeJS.LTS
```

### 4. Install Claude Code
```powershell
npm install -g @anthropic-ai/claude-code
```

### 5. Set API Key
```powershell
[System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", "sk-ant-...", "User")
```

### 6. Clone Workspace
```powershell
git clone https://github.com/DaCoderMan/claude-workspace.git C:\claude-workspace
```

## Verify SSH from VPS
```bash
ssh username@100.94.167.24   # bee-1
ssh username@100.116.216.124 # sparta-1
```

## Firewall
Windows Firewall should auto-allow sshd. If not:
```powershell
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```
