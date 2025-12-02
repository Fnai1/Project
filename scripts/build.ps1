# scripts/build.ps1 - Скрипт сборки 1С конфигурации
Write-Host "=== 1C Build Script ===" -ForegroundColor Cyan
Write-Host "Configuration: $env:CONFIG_NAME" -ForegroundColor Yellow

# Здесь будет реальная логика сборки 1С
# Пока создаем тестовый файл
$cfFile = "artifacts/build/$env:CONFIG_NAME.cf"
Write-Host "Creating CF file: $cfFile"

@"
# 1C Configuration
Name: $env:CONFIG_NAME
BuildDate: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Version: 1.0.0
"@ | Out-File -FilePath $cfFile -Encoding UTF8

Write-Host "Build completed" -ForegroundColor Green
