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

# Р’СЂРµРјРµРЅРЅР°СЏ С„Р°Р№Р»РѕРІР°СЏ РР‘
$tempIB = Join-Path $workDir 'tmpIB'
if (Test-Path $tempIB) { Remove-Item $tempIB -Recurse -Force }

& $designer CREATEINFOBASE File="$tempIB" /DisableStartupMessages /UseHwLicenses- /Out "$workDir\create.log" | Out-Null

# РћР±РЅРѕРІР»РµРЅРёРµ РёР· С…СЂР°РЅРёР»РёС‰Р° Рё РІС‹РіСЂСѓР·РєР° CF
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
