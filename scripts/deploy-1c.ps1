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
