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
Write-Host "Executing: $thin $($cmd[0..3] -join ' ')..."
Write-Host "=========================================="

try {
  $output = & $thin $cmd 2>&1
  $exitCode = $LASTEXITCODE
  
  if ($output) {
    Write-Host "Output: $output"
  }
  Write-Host "Exit code: $exitCode"
  
  # Exit codes 0-1 are usually OK for quick startup/shutdown
  if ($exitCode -eq 0 -or $exitCode -eq 1) {
    Write-Host "=========================================="
    Write-Host "Smoke test PASSED"
    Write-Host "=========================================="
    exit 0
  } else {
    Write-Host "=========================================="
    Write-Error "Smoke test FAILED - 1C returned exit code: $exitCode"
    Write-Host "=========================================="
    exit 1
  }
}
catch {
  Write-Host "=========================================="
  Write-Error "Smoke test FAILED - Exception: $($_.Exception.Message)"
  Write-Host "=========================================="
  exit 1
}
