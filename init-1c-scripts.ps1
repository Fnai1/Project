# Создание структуры каталогов
$root = Get-Location
$scriptsDir = Join-Path $root "scripts"
$testsDir   = Join-Path $root "tests"

New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
New-Item -ItemType Directory -Path $testsDir   -Force | Out-Null

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
$workDir = Join-Path $PSScriptRoot '..\configs\work'
New-Item -ItemType Directory -Force -Path $workDir | Out-Null

# Временная файловая ИБ
$tempIB = Join-Path $workDir 'tmpIB'
if (Test-Path $tempIB) { Remove-Item $tempIB -Recurse -Force }

& $designer CREATEINFOBASE File="$tempIB" /DisableStartupMessages /UseHwLicenses- /Out "$workDir\create.log" | Out-Null

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
  Write-Error "Build failed. See $workDir\build.log"
  exit 1
}
Write-Host "CF built: $OutCf"
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

$auth = @()
if ($IBUser) { $auth += "/N`"$IBUser`"" }
if ($IBPwd)  { $auth += "/P`"$IBPwd`"" }

$cmd = @(
  'DESIGNER',
  $Infobase,
  '/DisableStartupMessages',
  $auth,
  "/LoadCfg`"$Cf`"",
  '/UpdateDBCfg -force'
)

& $designer $cmd 2>&1 | Tee-Object -FilePath "artifacts\logs\deploy-apply.log"
if ($LASTEXITCODE -ne 0) {
  Write-Error "Deploy failed"
  exit 1
}
Write-Host "Deploy OK"
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
$auth = @()
if ($IBUser) { $auth += "/N`"$IBUser`"" }
if ($IBPwd)  { $auth += "/P`"$IBPwd`"" }

& $designer DESIGNER $Infobase '/DisableStartupMessages' $auth "/LoadCfg`"$BackupCf`"" '/UpdateDBCfg -force'
if ($LASTEXITCODE -ne 0) {
  Write-Error "Rollback failed"
  exit 1
}
Write-Host "Rollback OK"
'@

Set-Content -Path (Join-Path $scriptsDir "rollback-1c.ps1") -Value $rollback1c -Encoding UTF8


############ simple-build.ps1 ############
$simpleBuild = @'
param(
  [Parameter(Mandatory)] [string]$Source,
  [Parameter(Mandatory)] [string]$BackupDir
)
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
$target = Join-Path $BackupDir ("andreym-" + $ts + ".cf")
Copy-Item $Source $target -Force
Write-Host "Backup created: $target"
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
$auth = @()
if ($IBUser) { $auth += "/N`"$IBUser`"" }
if ($IBPwd)  { $auth += "/P`"$IBPwd`"" }

& $thin ENTERPRISE $Infobase '/DisableStartupMessages' $auth '/ExecuteMode' '/Command "MESSAGE Done"'
if ($LASTEXITCODE -ne 0) {
  Write-Error "Smoke failed"
  exit 1
}
Write-Host "Smoke OK"
'@

Set-Content -Path (Join-Path $testsDir "smoke.ps1") -Value $smoke -Encoding UTF8

Write-Host "Все скрипты созданы в папках 'scripts' и 'tests'."
