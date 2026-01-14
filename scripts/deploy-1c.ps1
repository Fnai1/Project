param(
  [Parameter(Mandatory)] [string]$Platform,
  [Parameter(Mandatory)] [string]$Infobase,
  [string]$IBUser = "",
  [string]$IBPwd = "",
  [Parameter(Mandatory)] [string]$Cf
)

$designer = Join-Path $Platform 'bin\1cv8.exe'

if (-not (Test-Path $designer)) {
  Write-Error "1C platform not found: $designer"
  exit 1
}

if (-not (Test-Path $Cf)) {
  Write-Error "CF file not found: $Cf"
  exit 1
}

Write-Host "=========================================="
Write-Host "Starting deployment"
Write-Host "=========================================="
Write-Host "Platform: $Platform"
Write-Host "Infobase: $Infobase"
Write-Host "CF file: $Cf"
$cfSize = (Get-Item $Cf).Length / 1KB
Write-Host "CF size: $([math]::Round($cfSize, 2)) KB"

$cmd = @(
  'DESIGNER',
  $Infobase,
  '/DisableStartupMessages'
)

if ($IBUser) { 
  $cmd += "/N`"$IBUser`""
  Write-Host "User: $IBUser"
} else {
  Write-Host "User: (none)"
}

if ($IBPwd) { 
  $cmd += "/P`"$IBPwd`""
  Write-Host "Password: ***"
} else {
  Write-Host "Password: (none)"
}

$cmd += "/LoadCfg`"$Cf`"",
        '/UpdateDBCfg',
        '-force'

Write-Host "=========================================="
Write-Host "Executing: $designer $($cmd[0..5] -join ' ')..."
Write-Host "=========================================="

# Ensure logs directory exists
$logsDir = "artifacts\logs"
if (-not (Test-Path $logsDir)) {
  New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

& $designer $cmd 2>&1 | Tee-Object -FilePath "$logsDir\deploy-apply.log"

if ($LASTEXITCODE -ne 0) {
  Write-Host "=========================================="
  Write-Error "Deployment FAILED with exit code: $LASTEXITCODE"
  Write-Host "=========================================="
  Write-Host "Last 30 lines of log:"
  Get-Content "$logsDir\deploy-apply.log" -ErrorAction SilentlyContinue | Select-Object -Last 30
  exit 1
}

Write-Host "=========================================="
Write-Host "Deployment completed successfully"
Write-Host "=========================================="
