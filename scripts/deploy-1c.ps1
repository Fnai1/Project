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

# Resolve to absolute path
$CfAbsolute = (Resolve-Path $Cf).Path

Write-Host "=========================================="
Write-Host "Starting deployment"
Write-Host "=========================================="
Write-Host "Platform: $Platform"
Write-Host "Infobase: $Infobase"
Write-Host "CF file (relative): $Cf"
Write-Host "CF file (absolute): $CfAbsolute"
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

# Use absolute path for LoadCfg
$cmd += "/LoadCfg `"$CfAbsolute`"",
        '/UpdateDBCfg',
        '-force'

Write-Host "=========================================="
Write-Host "Full command:"
Write-Host "$designer $($cmd -join ' ')"
Write-Host "=========================================="

# Ensure logs directory exists
$logsDir = "artifacts\logs"
if (-not (Test-Path $logsDir)) {
  New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

$logFile = "$logsDir\deploy-apply.log"
Write-Host "Log file: $logFile"
Write-Host "=========================================="

# Run with explicit output capture
$process = Start-Process -FilePath $designer `
                         -ArgumentList $cmd `
                         -Wait `
                         -PassThru `
                         -RedirectStandardOutput "$logsDir\deploy-stdout.log" `
                         -RedirectStandardError "$logsDir\deploy-stderr.log" `
                         -NoNewWindow

$exitCode = $process.ExitCode

Write-Host "=========================================="
Write-Host "Process finished with exit code: $exitCode"
Write-Host "=========================================="

# Show stdout
if (Test-Path "$logsDir\deploy-stdout.log") {
  $stdout = Get-Content "$logsDir\deploy-stdout.log" -Raw
  if ($stdout) {
    Write-Host "STDOUT:"
    Write-Host $stdout
  }
}

# Show stderr
if (Test-Path "$logsDir\deploy-stderr.log") {
  $stderr = Get-Content "$logsDir\deploy-stderr.log" -Raw
  if ($stderr) {
    Write-Host "STDERR:"
    Write-Host $stderr
  }
}

if ($exitCode -ne 0) {
  Write-Host "=========================================="
  Write-Error "Deployment FAILED with exit code: $exitCode"
  Write-Host "=========================================="
  Write-Host "Possible issues:"
  Write-Host "  1. Database is locked (check Task Manager for 1cv8.exe)"
  Write-Host "  2. OneDrive sync conflict"
  Write-Host "  3. Insufficient permissions"
  Write-Host "  4. Corrupted CF file"
  Write-Host "  5. Wrong infobase path format"
  Write-Host "=========================================="
  exit 1
}

Write-Host "=========================================="
Write-Host "Deployment completed successfully"
Write-Host "=========================================="
