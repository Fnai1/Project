# 1C CI/CD Project

## 📁 Структура проекта
├── .github/workflows/
│ └── ci.yml # GitHub Actions workflow
├── scripts/
│ ├── build-1c.ps1 # Сборка конфигурации
│ ├── deploy-1c.ps1 # Деплой
│ └── rollback-1c.ps1 # Откат
├── artifacts/
│ ├── build/ # Собранные CF файлы
│ ├── backups/ # Backup версии
│ └── logs/ # Логи выполнения
└── README.md # Документация

text

## ⚙️ Настройка
1. Настройте Secrets в GitHub
2. Укажите путь к хранилищу 1С
3. Укажите сервера test/production

## 🛠 Использование
### Автоматическая сборка
При push в main/develop ветки автоматически:
1. Инициализация окружения
2. Сборка конфигурации
3. Тестирование

### Ручной деплой
1. Откройте Actions
2. Выберите "1C CI/CD Pipeline"
3. Нажмите "Run workflow"
4. Выберите окружение (test/production)

## 🔧 Скрипты
- `build-1c.ps1` - сборка CF файла
- `deploy-1c.ps1` - развертывание на сервер
- `rollback-1c.ps1` - откат к предыдущей версии

