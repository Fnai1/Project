param(
  [Parameter(Mandatory)] [string]$Source,
  [Parameter(Mandatory)] [string]$BackupDir,
  [string]$Prefix = "backup"
)

if (-not (Test-Path $Source)) {
  Write-Error "Source file not found: $Source"
  exit 1
}

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
$target = Join-Path $BackupDir ("$Prefix-" + $ts + ".cf")

try {
  Copy-Item $Source $target -Force
  Write-Host "Backup created: $target"
}
catch {
  Write-Error "Failed to create backup: $($_.Exception.Message)"
  exit 1
}
