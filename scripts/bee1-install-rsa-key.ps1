# Bee-1 RSA Key Install — authenticates bee-1 TO VPS for reverse tunnel
Write-Host "=== Installing bee1_rsa key ===" -ForegroundColor Cyan

$sshDir = "$env:USERPROFILE\.ssh"
if (!(Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force | Out-Null }

$keyPath = "$env:USERPROFILE\.ssh\bee1_rsa"

# Write key with Unix line endings (critical for SSH)
$keyContent = @"
-----BEGIN OPENSSH PRIVATE KEY-----
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
-----END OPENSSH PRIVATE KEY-----
"@

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$normalized = $keyContent.Replace("`r`n","`n").Replace("`r","`n").TrimEnd() + "`n"
[System.IO.File]::WriteAllBytes($keyPath, $utf8NoBom.GetBytes($normalized))

# Strict permissions
icacls $keyPath /inheritance:r /grant "${env:USERNAME}:(R)" /grant "SYSTEM:(R)" 2>$null
Write-Host "Key installed at $keyPath" -ForegroundColor Green

# Update reverse tunnel to use new key
$tunnelScript = "$env:USERPROFILE\claude-workspace\scripts\tunnel.ps1"
if (Test-Path $tunnelScript) {
    $content = Get-Content $tunnelScript -Raw
    $content = $content -replace 'bee_id','bee1_rsa'
    Set-Content -Path $tunnelScript -Value $content
    Write-Host "tunnel.ps1 updated to use bee1_rsa" -ForegroundColor Green
}

# Restart tunnel
Stop-ScheduledTask -TaskName "BeeReverseTunnel" -ErrorAction SilentlyContinue
Start-Sleep 2
Start-ScheduledTask -TaskName "BeeReverseTunnel"
Write-Host "Tunnel restarted with new key" -ForegroundColor Green

# Quick test
Write-Host "Testing connection to VPS..." -ForegroundColor Yellow
$result = ssh -o StrictHostKeyChecking=no -o ConnectTimeout=8 -i $keyPath claude@65.109.230.136 "echo VPS_OK" 2>&1
if ($result -match "VPS_OK") {
    Write-Host "SUCCESS: bee-1 can reach VPS!" -ForegroundColor Green
} else {
    Write-Host "Result: $result" -ForegroundColor Red
}
