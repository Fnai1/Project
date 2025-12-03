param(
  [Parameter(Mandatory)] [string]$Source,
  [Parameter(Mandatory)] [string]$BackupDir
)
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
$target = Join-Path $BackupDir ("andreym-" + $ts + ".cf")
Copy-Item $Source $target -Force
Write-Host "Backup created: $target"
