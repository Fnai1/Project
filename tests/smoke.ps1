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
  
  # Handle case where exit code is null/empty
  if ($null -eq $exitCode -or $exitCode -eq "") {
    Write-Host "Exit code: (empty - process may not have started)"
    Write-Host "Output: $output"
    Write-Host "=========================================="
    Write-Error "Smoke test FAILED - 1C process did not return exit code"
    Write-Host "=========================================="
    exit 1
  }
  
  if ($output) {
    Write-Host "Output: $output"
  }
  Write-Host "Exit code: $exitCode"
  
  # Exit code 0 means success
  # Exit code 1 with OneDrive path might be a permissions issue
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
