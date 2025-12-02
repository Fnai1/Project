# scripts/simple-build.ps1
Write-Host "Simple build script"

$buildDir = "artifacts/build"
$configName = "andreym"
$cfFile = "$buildDir/$configName.cf"

# Создаем директорию
New-Item -ItemType Directory -Path $buildDir -Force

# Создаем простой CF файл
echo "# Simple 1C Configuration" > $cfFile
echo "Name: $configName" >> $cfFile
echo "Date: $(Get-Date)" >> $cfFile
echo "Build: Test" >> $cfFile

Write-Host "File created: $cfFile"
Write-Host "File exists: $(Test-Path $cfFile)"
