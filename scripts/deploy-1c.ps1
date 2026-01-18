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

# Parse infobase path
if ($Infobase -match '^/F(.+)$') {
  $dbPath = $matches[1]
  Write-Host "Parsed DB path: $dbPath"
  
  # Check if database exists
  if (-not (Test-Path $dbPath)) {
    Write-Error "Database path does not exist: $dbPath"
    Write-Host "Please create the infobase first or check the path"
    exit 1
  }
  
  # Check for 1Cv8.1CD file
  $mainFile = Join-Path $dbPath "1Cv8.1CD"
  if (-not (Test-Path $mainFile)) {
    Write-Warning "Main database file not found: $mainFile"
    Write-Host "This might be a new/empty infobase"
  } else {
    Write-Host "Database file found: $mainFile"
    $dbSize = (Get-Item $mainFile).Length / 1MB
    Write-Host "Database size: $([math]::Round($dbSize, 2)) MB"
  }
}

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
        '/UpdateDBCfg'

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

# Kill any hanging 1C processes first
Get-Process -Name "1cv8" -ErrorAction SilentlyContinue | ForEach-Object {
  Write-Warning "Killing hanging 1C process (PID: $($_.Id))"
  Stop-Process -Id $_.Id -Force
  Start-Sleep -Seconds 2
}

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
  $stdout = Get-Content "$logsDir\deploy-stdout.log" -Raw -ErrorAction SilentlyContinue
  if ($stdout -and $stdout.Trim()) {
    Write-Host "STDOUT:"
    Write-Host $stdout
  } else {
    Write-Host "STDOUT: (empty)"
  }
}

# Show stderr  
if (Test-Path "$logsDir\deploy-stderr.log") {
  $stderr = Get-Content "$logsDir\deploy-stderr.log" -Raw -ErrorAction SilentlyContinue
  if ($stderr -and $stderr.Trim()) {
    Write-Host "STDERR:"
    Write-Host $stderr
  } else {
    Write-Host "STDERR: (empty)"
  }
}

if ($exitCode -ne 0) {
  Write-Host "=========================================="
  Write-Error "Deployment FAILED with exit code: $exitCode"
  Write-Host "=========================================="
  Write-Host "Possible issues:"
  Write-Host "  1. Database is locked by another process (OneDrive, antivirus)"
  Write-Host "  2. OneDrive sync conflict - MOVE DB OUT OF ONEDRIVE"
  Write-Host "  3. Insufficient permissions on database folder"
  Write-Host "  4. Database is corrupted or in use"
  Write-Host "  5. 1C platform version mismatch"
  Write-Host ""
  Write-Host "RECOMMENDED: Move database to C:\Databases\InfoBase10"
  Write-Host "             Then update TEST_IB_CONN secret to /FC:\Databases\InfoBase10"
  Write-Host "=========================================="
  exit 1
}

Write-Host "=========================================="
Write-Host "Deployment completed successfully"
Write-Host "=========================================="
