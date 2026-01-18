param(
  [Parameter(Mandatory)] [string]$Platform,
  [Parameter(Mandatory)] [string]$Storage,
  [Parameter(Mandatory)] [string]$StorageUser,
  [string]$StoragePwd = "",
  [Parameter(Mandatory)] [string]$OutCf
)

$designer = Join-Path $Platform 'bin\1cv8.exe'

if (-not (Test-Path $designer)) {
  Write-Error "1C platform not found: $designer"
  exit 1
}

$workDir = Join-Path $PSScriptRoot '..\configs\work'
New-Item -ItemType Directory -Force -Path $workDir | Out-Null

# Create temporary file infobase
$tempIB = Join-Path $workDir 'tmpIB'
if (Test-Path $tempIB) { Remove-Item $tempIB -Recurse -Force }

Write-Host "Creating temporary infobase..."
& $designer CREATEINFOBASE File="$tempIB" /DisableStartupMessages /UseHwLicenses- /Out "$workDir\create.log" | Out-Null

if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to create temporary infobase"
  exit 1
}

Write-Host "Connecting to configuration repository: $Storage"
Write-Host "User: $StorageUser"

# Build common repo args
$repoArgs = @(
  "`/ConfigurationRepositoryF`"$Storage`"",
  "`/ConfigurationRepositoryN`"$StorageUser`""
)

if ($StoragePwd) {
  $repoArgs += "`/ConfigurationRepositoryP`"$StoragePwd`""
  Write-Host "Using password: ***"
} else {
  $repoArgs += '/ConfigurationRepositoryP""'
  Write-Host "Using empty password"
}

# 1) Bind tmp infobase to repository (important for UpdateCfg)
$bindCmd = @(
  'DESIGNER',
  "`/F`"$tempIB`"",
  '/DisableStartupMessages'
) + $repoArgs + @(
  '/ConfigurationRepositoryBindCfg'
)

Write-Host "Binding infobase to configuration repository..."
Write-Host "Executing: $designer $($bindCmd -join ' ')"
& $designer $bindCmd 2>&1 | Tee-Object -FilePath "$workDir\bind.log"

if ($LASTEXITCODE -ne 0) {
  Write-Error "Bind failed. See $workDir\bind.log"
  Get-Content "$workDir\bind.log" | Select-Object -Last 50
  exit 1
}

# 2) Update from repository and dump configuration
$buildCmd = @(
  'DESIGNER',
  "`/F`"$tempIB`"",
  '/DisableStartupMessages'
) + $repoArgs + @(
  '/ConfigurationRepositoryUpdateCfg',
  '-force',
  "`/DumpCfg`"$OutCf`""
)

Write-Host "Updating configuration from repository and dumping CF..."
Write-Host "Executing: $designer $($buildCmd -join ' ')"
& $designer $buildCmd 2>&1 | Tee-Object -FilePath "$workDir\build.log"

if ($LASTEXITCODE -ne 0 -or -not (Test-Path $OutCf)) {
  Write-Error "Build failed. See $workDir\build.log"
  Get-Content "$workDir\build.log" | Select-Object -Last 50
  exit 1
}

Write-Host "CF file successfully built: $OutCf"
$cfSize = (Get-Item $OutCf).Length / 1KB
Write-Host "CF file size: $([math]::Round($cfSize, 2)) KB"
