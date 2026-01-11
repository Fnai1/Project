# Создание структуры каталогов
$root = Get-Location
$scriptsDir = Join-Path $root "scripts"
$testsDir   = Join-Path $root "tests"
$logsDir    = Join-Path $root "artifacts\logs"

New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
New-Item -ItemType Directory -Path $testsDir   -Force | Out-Null
New-Item -ItemType Directory -Path $logsDir    -Force | Out-Null

############ build-1c.ps1 ############
$build1c = @'
param(
  [Parameter(Mandatory)] [string]$Platform,
  [Parameter(Mandatory)] [string]$Storage,
  [Parameter(Mandatory)] [string]$StorageUser,
  [Parameter(Mandatory)] [string]$StoragePwd,
  [Parameter(Mandatory)] [string]$OutCf
)

$designer = Join-Path $Platform '1cv8.exe'
if (-not (Test-Path $designer)) {
  Write-Error "Designer not found: $designer"
  exit 1
}

$workDir = Join-Path $PSScriptRoot '..\configs\work'
New-Item -ItemType Directory -Force -Path $workDir | Out-Null

# Временная файловая ИБ
$tempIB = Join-Path $workDir 'tmpIB'
if (Test-Path $tempIB) { Remove-Item $tempIB -Recurse -Force }

try {
  & $designer CREATEINFOBASE File="$tempIB" /DisableStartupMessages /UseHwLicenses- /Out "$workDir\create.log"
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to create infobase"
  }

  # Обновление из хранилища и выгрузка CF
  $cmd = @(
    'DESIGNER',
    "/F`"$tempIB`"",
    '/DisableStartupMessages',
    "/ConfigurationRepositoryF`"$Storage`"",
    "/ConfigurationRepositoryN`"$StorageUser`"",
    "/ConfigurationRepositoryP`"$StoragePwd`"",
    '/ConfigurationRepositoryUpdateCfg -force',
    "/DumpCfg`"$OutCf`""
  )

  & $designer $cmd 2>&1 | Tee-Object -FilePath "$workDir\build.log"
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path $OutCf)) {
    throw "Build failed. See $workDir\build.log"
  }
  Write-Host "CF built: $OutCf"
}
catch {
  Write-Error $_.Exception.Message
  exit 1
}
'@

Set-Content -Path (Join-Path $scriptsDir "build-1c.ps1") -Value $build1c -Encoding UTF8


############ deploy-1c.ps1 ############
$deploy1c = @'
param(
  [Parameter(Mandatory)] [string]$Platform,
  [Parameter(Mandatory)] [string]$Infobase,   # /F path or /S srv\ibase
  [string]$IBUser,
  [string]$IBPwd,
  [Parameter(Mandatory)] [string]$Cf
)

$designer = Join-Path $Platform '1cv8.exe'
if (-not (Test-Path $designer)) {
  Write-Error "Designer not found: $designer"
  exit 1
}

if (-not (Test-Path $Cf)) {
  Write-Error "CF file not found: $Cf"
  exit 1
}

$logsDir = Join-Path $PSScriptRoot '..\artifacts\logs'
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null

$cmd = @(
  'DESIGNER',
  $Infobase,
  '/DisableStartupMessages'
)

if ($IBUser) { $cmd += "/N`"$IBUser`"" }
if ($IBPwd)  { $cmd += "/P`"$IBPwd`"" }

$cmd += "/LoadCfg`"$Cf`""
$cmd += '/UpdateDBCfg -force'

try {
  & $designer $cmd 2>&1 | Tee-Object -FilePath "$logsDir\deploy-apply.log"
  if ($LASTEXITCODE -ne 0) {
    throw "Deploy failed"
  }
  Write-Host "Deploy OK"
}
catch {
  Write-Error $_.Exception.Message
  exit 1
}
'@

Set-Content -Path (Join-Path $scriptsDir "deploy-1c.ps1") -Value $deploy1c -Encoding UTF8


############ rollback-1c.ps1 ############
$rollback1c = @'
param(
  [Parameter(Mandatory)] [string]$Platform,
  [Parameter(Mandatory)] [string]$Infobase,
  [Parameter(Mandatory)] [string]$BackupCf,
  [string]$IBUser,
  [string]$IBPwd
)

$designer = Join-Path $Platform '1cv8.exe'
if (-not (Test-Path $designer)) {
  Write-Error "Designer not found: $designer"
  exit 1
}

if (-not (Test-Path $BackupCf)) {
  Write-Error "Backup CF file not found: $BackupCf"
  exit 1
}

$logsDir = Join-Path $PSScriptRoot '..\artifacts\logs'
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null

$cmd = @(
  'DESIGNER',
  $Infobase,
  '/DisableStartupMessages'
)

if ($IBUser) { $cmd += "/N`"$IBUser`"" }
if ($IBPwd)  { $cmd += "/P`"$IBPwd`"" }

$cmd += "/LoadCfg`"$BackupCf`""
$cmd += '/UpdateDBCfg -force'

try {
  & $designer $cmd 2>&1 | Tee-Object -FilePath "$logsDir\rollback.log"
  if ($LASTEXITCODE -ne 0) {
    throw "Rollback failed"
  }
  Write-Host "Rollback OK"
}
catch {
  Write-Error $_.Exception.Message
  exit 1
}
'@

Set-Content -Path (Join-Path $scriptsDir "rollback-1c.ps1") -Value $rollback1c -Encoding UTF8


############ simple-build.ps1 ############
$simpleBuild = @'
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
'@

Set-Content -Path (Join-Path $scriptsDir "simple-build.ps1") -Value $simpleBuild -Encoding UTF8


############ tests\smoke.ps1 ############
$smoke = @'
param(
  [Parameter(Mandatory)] [string]$Platform,
  [Parameter(Mandatory)] [string]$Infobase,
  [string]$IBUser,
  [string]$IBPwd
)

$thin = Join-Path $Platform '1cv8.exe'
if (-not (Test-Path $thin)) {
  Write-Error "1cv8.exe not found: $thin"
  exit 1
}

$cmd = @(
  'ENTERPRISE',
  $Infobase,
  '/DisableStartupMessages'
)

if ($IBUser) { $cmd += "/N`"$IBUser`"" }
if ($IBPwd)  { $cmd += "/P`"$IBPwd`"" }

$cmd += '/ExecuteMode'
$cmd += '/Command "MESSAGE Done"'

try {
  & $thin $cmd
  if ($LASTEXITCODE -ne 0) {
    throw "Smoke test failed"
  }
  Write-Host "Smoke OK"
}
catch {
  Write-Error $_.Exception.Message
  exit 1
}
'@

Set-Content -Path (Join-Path $testsDir "smoke.ps1") -Value $smoke -Encoding UTF8

Write-Host "Все скрипты созданы в папках 'scripts' и 'tests'."
