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
