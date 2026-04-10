# Bee-1 RSA Key Install — connects bee-1 TO VPS for reverse tunnel
Write-Host "=== Installing bee1_rsa key ===" -ForegroundColor Cyan

$keyContent = @"
-----BEGIN OPENSSH PRIVATE KEY-----
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
-----END OPENSSH PRIVATE KEY-----
"@

$keyPath = "$env:USERPROFILE\.ssh\bee1_rsa"
$sshDir = "$env:USERPROFILE\.ssh"
if (!(Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force | Out-Null }

# Write with Unix line endings (critical for SSH keys)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$keyBytes = $utf8NoBom.GetBytes($keyContent.Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd() + "`n")
[System.IO.File]::WriteAllBytes($keyPath, $keyBytes)

# Set permissions - only owner can read
icacls $keyPath /inheritance:r /grant "${env:USERNAME}:(R)" /grant "SYSTEM:(R)" 2>$null

Write-Host "Key installed at $keyPath" -ForegroundColor Green
Write-Host "Test with: ssh -i $keyPath -o StrictHostKeyChecking=no claude@65.109.230.136 echo OK" -ForegroundColor Yellow
