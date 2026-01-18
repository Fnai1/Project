param(
  [Parameter(Mandatory)] [string]$Platform,
  [Parameter(Mandatory)] [string]$Infobase,
  [string]$IBUser = "",
  [string]$IBPwd = ""
)

$thin = Join-Path $Platform 'bin\1cv8.exe'

if (-not (Test-Path $thin)) {
  Write-Error "1C platform not found: $thin"
  exit 1
}

Write-Host "=========================================="
Write-Host "Starting smoke test"
Write-Host "=========================================="
Write-Host "Platform: $Platform"
Write-Host "1cv8.exe: $thin"
Write-Host "Infobase: $Infobase"

$cmd = @(
  'ENTERPRISE',
  $Infobase,
  '/DisableStartupMessages',
  '/DisableStartupDialogs'
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

Write-Host "=========================================="
Write-Host "Full command:"
Write-Host "$thin $($cmd -join ' ')"
Write-Host "=========================================="

# Ensure logs directory exists
$logsDir = "artifacts\logs"
if (-not (Test-Path $logsDir)) {
  New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

try {
  # Run with explicit output capture
  $process = Start-Process -FilePath $thin `
                           -ArgumentList $cmd `
                           -Wait `
                           -PassThru `
                           -RedirectStandardOutput "$logsDir\smoke-stdout.log" `
                           -RedirectStandardError "$logsDir\smoke-stderr.log" `
                           -NoNewWindow `
                           -ErrorAction Stop
  
  $exitCode = $process.ExitCode
  
  Write-Host "Exit code: $exitCode"
  
  # Show stdout
  if (Test-Path "$logsDir\smoke-stdout.log") {
    $stdout = Get-Content "$logsDir\smoke-stdout.log" -Raw
    if ($stdout) {
      Write-Host "STDOUT:"
      Write-Host $stdout
    }
  }
  
  # Show stderr
  if (Test-Path "$logsDir\smoke-stderr.log") {
    $stderr = Get-Content "$logsDir\smoke-stderr.log" -Raw
    if ($stderr) {
      Write-Host "STDERR:"
      Write-Host $stderr
    }
  }
  
  # Exit code 0 means success
  if ($exitCode -eq 0) {
    Write-Host "=========================================="
    Write-Host "Smoke test PASSED"
    Write-Host "=========================================="
    exit 0
  } else {
    Write-Host "=========================================="
    Write-Error "Smoke test FAILED - 1C returned exit code: $exitCode"
    Write-Host "=========================================="
    Write-Host "Possible causes:"
    Write-Host "  - Database locked by another process"
    Write-Host "  - OneDrive sync conflict"
    Write-Host "  - Insufficient permissions"
    Write-Host "  - Corrupted database"
    Write-Host "  - Previous deployment failed"
    Write-Host "=========================================="
    exit 1
  }
}
catch {
  Write-Host "=========================================="
  Write-Error "Smoke test FAILED - Exception: $($_.Exception.Message)"
  Write-Host "Full error: $($_ | Format-List -Force | Out-String)"
  Write-Host "=========================================="
  exit 1
}
