# Bee-1 Reverse SSH Tunnel to VPS
# Allows VPS to SSH into bee-1 even without Tailscale
# Run as Administrator

Write-Host "=== Setting up Bee-1 Reverse SSH Tunnel ===" -ForegroundColor Cyan

# Create the tunnel script
$tunnelScript = @'
while ($true) {
    Write-Host "$(Get-Date): Connecting reverse tunnel to VPS..."
    $proc = Start-Process -FilePath "ssh" -ArgumentList "-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=no -N -R 2222:localhost:22 claude@65.109.230.136 -i $env:USERPROFILE\.ssh\bee_id" -NoNewWindow -PassThru -Wait
    Write-Host "$(Get-Date): Tunnel disconnected (exit $($proc.ExitCode)), reconnecting in 10s..."
    Start-Sleep 10
}
'@

$scriptPath = "$env:USERPROFILE\claude-workspace\scripts\tunnel.ps1"
Set-Content -Path $scriptPath -Value $tunnelScript
Write-Host "Tunnel script created at $scriptPath" -ForegroundColor Green

# Create Windows Task Scheduler task
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$trigger2 = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

Register-ScheduledTask -TaskName "BeeReverseTunnel" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null
Write-Host "Task Scheduler task created: BeeReverseTunnel" -ForegroundColor Green

# Start it now immediately
Start-ScheduledTask -TaskName "BeeReverseTunnel"
Write-Host "Tunnel started now" -ForegroundColor Green
Write-Host ""
Write-Host "VPS can now SSH to bee-1 via: ssh -p 2222 jonat@localhost (from VPS)" -ForegroundColor Yellow
Write-Host "Or: ssh -p 2222 jonat@65.109.230.136 won't work - must be FROM the VPS" -ForegroundColor Yellow
