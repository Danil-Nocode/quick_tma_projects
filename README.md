# 🚀 Quickstart Telegram Mini App + Supabase

Производственно-готовый монорепо для создания Telegram Mini App с интеграцией Supabase, автоматическим деплоем и полной инфраструктурой.

## 📋 Содержание

- [Особенности](#особенности)
- [Архитектура](#архитектура)
- [Быстрый старт](#быстрый-старт)
- [Локальная разработка](#локальная-разработка)
- [Настройка Supabase](#настройка-supabase)
- [Настройка доменов](#настройка-доменов)
- [Первый деплой](#первый-деплой)
- [Настройка webhook](#настройка-webhook)
- [Обновления и мониторинг](#обновления-и-мониторинг)
- [API Documentation](#api-documentation)
- [Troubleshooting](#troubleshooting)

## ✨ Особенности

- 🤖 **Telegram Bot** - Fastify + Telegraf с webhook поддержкой
- ⚛️ **Mini App** - React + Vite с Telegram WebApp API
- 🗄️ **База данных** - Supabase с миграциями и RLS
- 🐳 **Docker** - Multi-stage сборка с оптимизацией
- 🔄 **CI/CD** - GitHub Actions с автоматическим деплоем
- 🌐 **Nginx** - Reverse proxy + SSL + security headers
- 🔒 **Безопасность** - HMAC валидация, CORS, rate limiting
- 📊 **Мониторинг** - Health checks, логирование, метрики
- 🚀 **Production-ready** - Полная автоматизация инфраструктуры

## 🏗️ Архитектура

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Telegram      │    │     Nginx        │    │   Supabase      │
│     Bot         │◄──►│  Reverse Proxy   │◄──►│   Database      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │
         │              ┌─────────▼─────────┐
         │              │    API Service    │
         │              │ (Fastify+Telegraf)│
         │              └─────────┬─────────┘
         │                        │
┌────────▼────────┐    ┌─────────▼─────────┐
│  Mini App       │    │   Web Service     │
│ (React + Vite)  │◄──►│     (Nginx)       │
└─────────────────┘    └───────────────────┘
```

## 🚀 Быстрый старт

### 1. Клонирование репозитория

```bash
git clone https://github.com/your-username/quickstart-telegram-miniapp-supabase.git
cd quickstart-telegram-miniapp-supabase
```

### 2. Установка зависимостей

```bash
# Установка pnpm (если не установлен)
npm install -g pnpm@8.15.1

# Установка зависимостей
pnpm install
```

### 3. Настройка переменных окружения

```bash
# Копирование примера конфигурации
cp env.example .env

# Редактирование переменных
nano .env
```

Замените все плейсхолдеры `[[...]]` на реальные значения:

```env
# App Configuration
NODE_ENV=production
API_DOMAIN=api.yourapp.com
APP_DOMAIN=app.yourapp.com

# Telegram Bot
BOT_TOKEN=your_bot_token_from_botfather
WEBHOOK_SECRET=random_secret_string_32_chars
WEBHOOK_URL=https://api.yourapp.com/webhook

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Docker Registry (например, ghcr.io, docker.io)
REGISTRY=ghcr.io/your-username
REGISTRY_USER=your_username
REGISTRY_TOKEN=your_access_token

# VPS Deployment
SSH_HOST=your.server.ip
SSH_USER=deploy
SSH_PORT=22
PROJECT_SLUG=telegram-miniapp

# SSL
CERTBOT_EMAIL=your-email@example.com
```

## 💻 Локальная разработка

### 1. Запуск в режиме разработки

```bash
# Запуск всех сервисов
pnpm dev

# Или отдельно:
pnpm --filter api dev    # API на порту 3001
pnpm --filter web dev    # Web на порту 3000
```

### 2. Запуск с Docker Compose

```bash
# Разработка с Docker
docker-compose -f docker-compose.dev.yml up -d

# Просмотр логов
docker-compose -f docker-compose.dev.yml logs -f
```

### 3. Тестирование

```bash
# Проверка типов
pnpm type-check

# Линтинг
pnpm lint

# Сборка
pnpm build
```

## 🗄️ Настройка Supabase

### 1. Создание проекта

1. Перейдите на [supabase.com](https://supabase.com)
2. Создайте новый проект
3. Скопируйте URL проекта и ключи API

### 2. Настройка базы данных

```bash
# Запуск миграций
pnpm --filter api db:migrate

# Заполнение тестовыми данными (опционально)
pnpm --filter api db:seed

# Проверка статуса БД
pnpm --filter api db:status
```

### 3. Настройка RLS (Row Level Security)

Миграции автоматически настраивают RLS политики:

- `Service role` - полный доступ ко всем данным
- `Authenticated users` - доступ только к своим данным

## 🌐 Настройка доменов

### 1. DNS настройки

Создайте A-записи для ваших доменов:

```
api.yourapp.com → IP_ВАШЕГО_СЕРВЕРА
app.yourapp.com → IP_ВАШЕГО_СЕРВЕРА
```

### 2. Проверка DNS

```bash
# Проверка разрешения DNS
dig api.yourapp.com
dig app.yourapp.com
```

## 🚀 Первый деплой

### 1. Подготовка сервера

```bash
# Запуск скрипта настройки сервера (на VPS)
curl -sSL https://raw.githubusercontent.com/your-repo/quickstart-telegram-miniapp-supabase/main/infra/scripts/server-setup.sh | bash
```

Или вручную:

```bash
# Копирование скрипта на сервер
scp infra/scripts/server-setup.sh user@your-server:/tmp/
ssh user@your-server "sudo bash /tmp/server-setup.sh"
```

### 2. Настройка SSL сертификатов

```bash
# На сервере
./infra/scripts/certbot-init.sh api.yourapp.com app.yourapp.com your-email@example.com
```

### 3. Настройка GitHub Secrets

В настройках репозитория GitHub → Settings → Secrets → Actions добавьте:

```
API_DOMAIN=api.yourapp.com
APP_DOMAIN=app.yourapp.com
BOT_TOKEN=your_bot_token
WEBHOOK_SECRET=your_webhook_secret
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
REGISTRY=ghcr.io/your-username
REGISTRY_USER=your_username
REGISTRY_TOKEN=your_github_token
SSH_HOST=your.server.ip
SSH_USER=deploy
SSH_PORT=22
SSH_PRIVATE_KEY=your_private_ssh_key
PROJECT_SLUG=telegram-miniapp
```

### 4. Запуск деплоя

```bash
# Автоматический деплой при push в main
git add .
git commit -m "Initial deployment"
git push origin main

# Или ручной деплой
./infra/scripts/deploy.sh
```

## 🤖 Настройка webhook

### 1. Автоматическая настройка

Webhook настраивается автоматически после деплоя. Проверить статус:

```bash
curl https://api.yourapp.com/api/webhook/info
```

### 2. Ручная настройка

```bash
# Установка webhook
curl -X POST "https://api.yourapp.com/api/webhook/set"

# Удаление webhook (для разработки)
curl -X DELETE "https://api.yourapp.com/api/webhook"
```

### 3. Тестирование бота

1. Откройте чат с вашим ботом в Telegram
2. Отправьте команду `/start`
3. Нажмите кнопку "🚀 Открыть Mini App"
4. Проверьте, что приложение загрузилось корректно

## 🔄 Обновления и мониторинг

### Автоматические обновления

Каждый push в ветку `main` автоматически:

1. ✅ Запускает тесты
2. 🐳 Собирает Docker образы
3. 🚀 Деплоит на сервер
4. 🔄 Запускает миграции БД
5. 🤖 Обновляет webhook

### Мониторинг

```bash
# Статус сервисов
docker-compose -f docker-compose.prod.yml ps

# Логи сервисов
docker-compose -f docker-compose.prod.yml logs -f api
docker-compose -f docker-compose.prod.yml logs -f web
docker-compose -f docker-compose.prod.yml logs -f nginx

# Проверка здоровья
curl https://api.yourapp.com/api/health
curl https://app.yourapp.com/health
```

### Резервное копирование

```bash
# Создание бэкапа
./infra/scripts/backup.sh

# Просмотр бэкапов
ls -la /opt/backups/
```

## 📚 API Documentation

### Health Endpoints

- `GET /health` - Базовая проверка здоровья
- `GET /api/health` - Проверка API
- `GET /api/health/detailed` - Детальная проверка с БД

### Telegram Endpoints

- `POST /webhook` - Telegram webhook endpoint
- `POST /api/webhook/set` - Установка webhook
- `GET /api/webhook/info` - Информация о webhook
- `DELETE /api/webhook` - Удаление webhook

### Application Endpoints

- `POST /api/ping` - Тест с валидацией Telegram данных

### Response Format

```json
{
  "status": "ok",
  "message": "Response message",
  "data": {},
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

## 🔧 Troubleshooting

### Частые проблемы

#### 1. Webhook не работает

```bash
# Проверка webhook
curl https://api.yourapp.com/api/webhook/info

# Переустановка webhook
curl -X POST "https://api.yourapp.com/api/webhook/set"
```

#### 2. SSL сертификаты

```bash
# Проверка сертификата
openssl s_client -connect api.yourapp.com:443 -servername api.yourapp.com

# Обновление сертификатов
sudo certbot renew
```

#### 3. База данных не доступна

```bash
# Проверка подключения к Supabase
pnpm --filter api db:status

# Проверка переменных окружения
docker-compose -f docker-compose.prod.yml config
```

#### 4. Проблемы с сервисами

```bash
# Перезапуск сервисов
docker-compose -f docker-compose.prod.yml restart

# Полная пересборка
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build
```

### Логирование

Логи доступны в следующих местах:

- **API логи**: `docker logs tma-api`
- **Web логи**: `docker logs tma-web`
- **Nginx логи**: `/var/log/nginx/`
- **Системные логи**: `journalctl -u telegram-miniapp`

### Performance Monitoring

```bash
# Использование ресурсов
docker stats

# Дисковое пространство
df -h

# Системная нагрузка
htop
```

## 🤝 Вклад в проект

1. Fork репозитория
2. Создайте feature branch (`git checkout -b feature/amazing-feature`)
3. Commit изменения (`git commit -m 'Add amazing feature'`)
4. Push в branch (`git push origin feature/amazing-feature`)
5. Создайте Pull Request

## 📄 Лицензия

Этот проект лицензирован под MIT License - см. файл [LICENSE](LICENSE) для деталей.

## 🙏 Благодарности

- [Telegram Bot API](https://core.telegram.org/bots/api)
- [Telegram Mini Apps](https://core.telegram.org/bots/webapps)
- [Supabase](https://supabase.com)
- [Fastify](https://www.fastify.io)
- [React](https://reactjs.org)
- [Vite](https://vitejs.dev)

---

**🎉 Готово! Ваш Telegram Mini App готов к продакшену!**

Для получения помощи создайте [issue](https://github.com/your-repo/issues) или обратитесь к [документации](https://github.com/your-repo/wiki)