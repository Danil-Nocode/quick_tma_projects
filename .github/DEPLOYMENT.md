# GitHub Actions Deployment Guide

Этот файл содержит инструкции по настройке автоматического деплоя через GitHub Actions.

## GitHub Secrets Configuration

Добавьте следующие секреты в настройки репозитория:
**Settings** → **Secrets and variables** → **Actions** → **New repository secret**

### Основные домены и конфигурация
```
API_DOMAIN=api.yourapp.com
APP_DOMAIN=app.yourapp.com
```

### Telegram Bot настройки
```
BOT_TOKEN=1234567890:AABBCCDDEEFFgghhiijjkkllmmnnooppqqr
WEBHOOK_SECRET=super_secret_webhook_key_32_chars_min
```

### Supabase настройки
```
SUPABASE_URL=https://xyzabc123def.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Docker Registry настройки
```
REGISTRY=ghcr.io/your-username
REGISTRY_USER=your-github-username
REGISTRY_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### VPS Server настройки
```
SSH_HOST=123.456.789.012
SSH_USER=deploy
SSH_PORT=22
SSH_PRIVATE_KEY=-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAlwAAAAdzc2gtcnNh...
-----END OPENSSH PRIVATE KEY-----
```

### Дополнительные настройки
```
PROJECT_SLUG=telegram-miniapp
```

## SSH Key Setup

### 1. Генерация SSH ключа (на локальной машине)

```bash
ssh-keygen -t rsa -b 4096 -C "deploy@yourapp.com" -f ~/.ssh/deploy_key
```

### 2. Добавление публичного ключа на сервер

```bash
# Скопировать публичный ключ на сервер
ssh-copy-id -i ~/.ssh/deploy_key.pub deploy@your-server-ip

# Или вручную:
cat ~/.ssh/deploy_key.pub | ssh deploy@your-server-ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### 3. Добавление приватного ключа в GitHub Secrets

```bash
# Скопировать содержимое приватного ключа
cat ~/.ssh/deploy_key
```

Скопируйте полное содержимое (включая заголовки) и добавьте как `SSH_PRIVATE_KEY` в GitHub Secrets.

## Registry Authentication

### GitHub Container Registry (ghcr.io)

1. Перейдите в **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Создайте новый token с правами:
   - `write:packages`
   - `read:packages`
   - `delete:packages`
3. Добавьте token как `REGISTRY_TOKEN` в GitHub Secrets

### Docker Hub

```
REGISTRY=docker.io/your-username
REGISTRY_USER=your-dockerhub-username
REGISTRY_TOKEN=your-dockerhub-access-token
```

## Workflow Triggers

Деплой запускается при:

- **Push в ветку main** - автоматический деплой в production
- **Pull Request** - только тестирование (без деплоя)
- **Manual trigger** - ручной запуск workflow

## Environment Protection

Для защиты production окружения:

1. **Settings** → **Environments** → **New environment** → `production`
2. Добавьте правила:
   - **Required reviewers** - обязательное одобрение
   - **Wait timer** - задержка перед деплоем
   - **Deployment branches** - только main ветка

## Monitoring Deployment

### Просмотр логов деплоя

1. Перейдите в **Actions** tab
2. Выберите последний workflow run
3. Откройте шаги `Build and Push Images` и `Deploy to Production`

### Проверка статуса после деплоя

```bash
# Проверка API
curl -f https://api.yourapp.com/health

# Проверка Web App
curl -f https://app.yourapp.com/health

# Проверка webhook статуса
curl https://api.yourapp.com/api/webhook/info
```

## Troubleshooting

### Проблемы с SSH подключением

```bash
# Тест SSH подключения
ssh -i ~/.ssh/deploy_key deploy@your-server-ip "echo 'SSH connection works'"

# Проверка SSH ключа в GitHub
echo "SSH_PRIVATE_KEY должен содержать полный ключ включая заголовки"
```

### Проблемы с Docker Registry

```bash
# Тест подключения к registry
echo $REGISTRY_TOKEN | docker login $REGISTRY -u $REGISTRY_USER --password-stdin

# Проверка прав доступа
docker push $REGISTRY/test:latest
```

### Ошибки при деплое

1. Проверьте все секреты в GitHub
2. Убедитесь, что сервер доступен по SSH
3. Проверьте статус Docker на сервере
4. Просмотрите логи workflow в GitHub Actions

## Manual Deployment

Если нужно запустить деплой вручную:

1. Перейдите в **Actions** → **Build and Deploy**
2. Нажмите **Run workflow**
3. Выберите ветку и нажмите **Run workflow**

Или через локальный скрипт:

```bash
./infra/scripts/deploy.sh production
```
