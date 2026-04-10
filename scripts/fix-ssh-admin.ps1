# Fix for Windows OpenSSH: Admin users need key in ProgramData, not ~/.ssh
# Run as Administrator: irm https://raw.githubusercontent.com/DaCoderMan/bee-claude-workspace/main/scripts/fix-ssh-admin.ps1 | iex

$beeIdKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLPlKgGLLl8LUKPqSiTzGTdXs82re/ihQvXegZowkf/ vps-claude-to-bee-20260329"
$rsaKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCYYc+sL2Jv2V8Ce80DA6ARVBxccsktxuKdQQoVFQaDuiTfLFZGe92OI9OzWDP7CkW9qjn3MEGK7A5CBW1JEofcP1/DLYtg7SZvk8w3v3QYBPflB1+uEx048DqJmGrgYB9wTib9Bhhc1H3P0cjQh7Cd4JNE+4L9qvAL0PCO9im98jDnQSERFbjyQWYwh0PNRhtDQiWlGH9bRqzN3r0bSp4aCjnCwwa23hExbmUmovI5fEXayMLlrvh29CNOzKp6wHhaDqnfq+xteKsQpavyfgu/ct18NdTUNOCaoVUoexxddqh07vIBIrCiipftEcDDnRmiAFBcmJ1S4GgOn0BFINcV36TB7WSpIG0Y6SBLXMqvg5/QCrAb1OLHDMR69VRY2gu+yNmfPVMsTZCBWHb0KJeRpnsQDP4yhi3zgzm8Ucr08CvyVtSOQQBU13DG2NF1hijkXcubQKHsD/eWz9kjM3YXFkJLCkgrO/S1bwlWHuq+53H+czuB60fmr1xUcs7oUZU5ZKHl/5y6ZdIU/jRTUW9cS1kGlf+K69R6ovnbqgpQYjVoQi8n8t3M5LH0bXVlgO8N1B2HMYsef14bQ94ctDNebrUe8Df857+ZLgAaqxaryty2lykVOdcaOThNmOzgWu/LQhw5C7wPCndyoyfNpadHPEimM0H/Y+qjA8q8octQ4Q== claude@workitulife-prod"
$allKeys = "$beeIdKey`n$rsaKey"

# --- Admin authorized_keys (C:\ProgramData\ssh\) ---
$adminKeyFile = "C:\ProgramData\ssh\administrators_authorized_keys"
New-Item -ItemType File -Path $adminKeyFile -Force | Out-Null
Set-Content -Path $adminKeyFile -Value $allKeys
icacls $adminKeyFile /inheritance:r /grant "SYSTEM:(F)" /grant "Administrators:(F)" 2>$null
Write-Host "Admin authorized_keys written at $adminKeyFile" -ForegroundColor Green

# --- User authorized_keys (C:\Users\jonat\.ssh\) ---
$userSshDir = "C:\Users\jonat\.ssh"
$userKeyFile = "$userSshDir\authorized_keys"
if (!(Test-Path $userSshDir)) { New-Item -ItemType Directory -Path $userSshDir -Force | Out-Null }
New-Item -ItemType File -Path $userKeyFile -Force | Out-Null
Set-Content -Path $userKeyFile -Value $allKeys
icacls $userKeyFile /inheritance:r /grant "SYSTEM:(F)" /grant "Administrators:(F)" /grant "jonat:(F)" 2>$null
Write-Host "User authorized_keys written at $userKeyFile" -ForegroundColor Green

# --- Restart sshd ---
Restart-Service sshd
Write-Host "sshd restarted - VPS can now SSH in with bee_id or id_rsa" -ForegroundColor Green
