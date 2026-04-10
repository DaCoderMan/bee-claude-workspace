# Windows Machine SSH Setup — Manual Instructions

## For: bee-1 (100.94.167.24) and sparta-1 (100.116.216.124)

### Option A: Run the automated script

1. Open **PowerShell as Administrator**
2. Run:
```powershell
# Download and run setup script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DaCoderMan/bee-claude-workspace/main/scripts/setup-windows-ssh.ps1" -OutFile "$env:TEMP\setup.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\setup.ps1"
```

If the repo isn't pushed yet, copy the script manually from VPS:
```powershell
scp root@100.127.175.67:/opt/claude-workspace/scripts/setup-windows-ssh.ps1 $env:TEMP\setup.ps1
powershell -ExecutionPolicy Bypass -File "$env:TEMP\setup.ps1"
```

---

### Option B: Manual step-by-step

#### Step 1: Install OpenSSH Server

Open **PowerShell as Administrator**:
```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
```

#### Step 2: Add VPS public key

```powershell
# Create .ssh directory
mkdir "$env:USERPROFILE\.ssh" -Force

# Add the VPS public key
Add-Content "$env:USERPROFILE\.ssh\authorized_keys" "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCYYc+sL2Jv2V8Ce80DA6ARVBxccsktxuKdQQoVFQaDuiTfLFZGe92OI9OzWDP7CkW9qjn3MEGK7A5CBW1JEofcP1/DLYtg7SZvk8w3v3QYBPflB1+uEx048DqJmGrgYB9wTib9Bhhc1H3P0cjQh7Cd4JNE+4L9qvAL0PCO9im98jDnQSERFbjyQWYwh0PNRhtDQiWlGH9bRqzN3r0bSp4aCjnCwwa23hExbmUmovI5fEXayMLlrvh29CNOzKp6wHhaDqnfq+xteKsQpavyfgu/ct18NdTUNOCaoVUoexxddqh07vIBIrCiipftEcDDnRmiAFBcmJ1S4GgOn0BFINcV36TB7WSpIG0Y6SBLXMqvg5/QCrAb1OLHDMR69VRY2gu+yNmfPVMsTZCBWHb0KJeRpnsQDP4yhi3zgzm8Ucr08CvyVtSOQQBU13DG2NF1hijkXcubQKHsD/eWz9kjM3YXFkJLCkgrO/S1bwlWHuq+53H+czuB60fmr1xUcs7oUZU5ZKHl/5y6ZdIU/jRTUW9cS1kGlf+K69R6ovnbqgpQYjVoQi8n8t3M5LH0bXVlgO8N1B2HMYsef14bQ94ctDNebrUe8Df857+ZLgAaqxaryty2lykVOdcaOThNmOzgWu/LQhw5C7wPCndyoyfNpadHPEimM0H/Y+qjA8q8octQ4Q== claude@workitulife-prod"

# For admin users — Windows OpenSSH uses a separate file
Copy-Item "$env:USERPROFILE\.ssh\authorized_keys" "C:\ProgramData\ssh\administrators_authorized_keys" -Force
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "SYSTEM:(F)" /grant "Administrators:(F)"
```

#### Step 3: Install Claude CLI

```powershell
# Install Node.js if needed
winget install OpenJS.NodeJS.LTS

# Install Claude CLI
npm install -g @anthropic-ai/claude-code
```

#### Step 4: Create workspace

```powershell
mkdir "$env:USERPROFILE\claude-workspace" -Force
cd "$env:USERPROFILE\claude-workspace"
git clone https://github.com/DaCoderMan/bee-claude-workspace.git
```

#### Step 5: Create bee-claude.bat

Create `%USERPROFILE%\claude-workspace\bee-claude.bat`:
```batch
@echo off
cd /d "%USERPROFILE%\claude-workspace\bee-claude-workspace"
claude --dangerously-skip-permissions %*
```

#### Step 6: Verify

From VPS, test SSH:
```bash
# For bee-1
ssh yonatan@100.94.167.24 "hostname && echo OK"

# For sparta-1
ssh yonatan@100.116.216.124 "hostname && echo OK"
```

---

### Firewall Note

If SSH doesn't work, check Windows Firewall:
```powershell
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

### Troubleshooting

1. **Permission denied**: Check `C:\ProgramData\ssh\administrators_authorized_keys` permissions
2. **Connection refused**: Ensure `sshd` service is running: `Get-Service sshd`
3. **Tailscale not routing**: Run `tailscale ping 100.127.175.67` from Windows
