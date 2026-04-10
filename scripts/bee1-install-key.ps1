# Install bee_id SSH key on bee-1
# This key allows bee-1 to authenticate TO the VPS (claude@65.109.230.136)
# Run this ONCE before setting up the reverse tunnel

Write-Host "=== Installing bee_id SSH key ===" -ForegroundColor Cyan

$sshDir = "$env:USERPROFILE\.ssh"
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    Write-Host "Created $sshDir" -ForegroundColor Green
}

$keyPath = "$sshDir\bee_id"

$keyContent = @"
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACAyz5SoBiy5fC1Cj6kok8xk3V7PNq3v4oUL13oGaMJH/wAAAKDL1IOKy9SD
igAAAAtzc2gtZWQyNTUxOQAAACAyz5SoBiy5fC1Cj6kok8xk3V7PNq3v4oUL13oGaMJH/w
AAAEDv6AiZbwmnibJn837Q3NF7gctUdiNKDusFD82zfbxkKDLPlKgGLLl8LUKPqSiTzGTd
Xs82re/ihQvXegZowkf/AAAAGnZwcy1jbGF1ZGUtdG8tYmVlLTIwMjYwMzI5AQID
-----END OPENSSH PRIVATE KEY-----
"@

Set-Content -Path $keyPath -Value $keyContent -NoNewline

# Set permissions - only current user can read
icacls $keyPath /inheritance:r /grant:r "${env:USERNAME}:(R)" | Out-Null
Write-Host "Key installed at $keyPath with restricted permissions" -ForegroundColor Green
Write-Host ""
Write-Host "Next step: Run bee1-reverse-tunnel.ps1 as Administrator" -ForegroundColor Yellow
