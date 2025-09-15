# Настройка GitHub Actions Secrets

Для корректной работы CI/CD pipeline необходимо настроить следующие секреты в GitHub:

## Docker Registry Secrets

Перейдите в GitHub Repository → Settings → Secrets and variables → Actions

Добавьте следующие секреты:

### Registry Configuration
- **REGISTRY** - адрес вашего Docker Registry (например: `registry.digitalocean.com` или `ghcr.io`)
- **REGISTRY_USER** - имя пользователя для доступа к Registry 
- **REGISTRY_TOKEN** - токен или пароль для доступа к Registry
- **PROJECT_SLUG** - название проекта для создания образов (например: `my-tma-project`)

### VPS Deployment Secrets  
- **SSH_HOST** - IP адрес или домен вашего VPS сервера
- **SSH_USER** - пользователь для SSH подключения (обычно `root` или `ubuntu`)
- **SSH_PORT** - порт для SSH подключения (обычно `22`)
- **SSH_PRIVATE_KEY** - приватный SSH ключ для подключения к серверу

## Настройка для Docker Hub

Основываясь на вашем аккаунте `danilnocode`, используйте следующие значения:

```bash
# Docker Hub Configuration
REGISTRY=docker.io
REGISTRY_USER=danilnocode
REGISTRY_TOKEN=dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxx  # Ваш Personal Access Token
PROJECT_SLUG=quick-tma-project  # Или любое другое название проекта
```

## Примеры для других Registry

```bash
# GitHub Container Registry
REGISTRY=ghcr.io
REGISTRY_USER=your-github-username  
REGISTRY_TOKEN=your-github-personal-access-token

# DigitalOcean Container Registry
REGISTRY=registry.digitalocean.com
REGISTRY_USER=your-do-registry-token
REGISTRY_TOKEN=your-do-registry-token
```

## Проверка настройки

После добавления секретов:

1. Сделайте commit и push в ветку `main`
2. Перейдите в GitHub → Actions и проверьте, что workflow запустился без ошибок
3. Убедитесь, что Docker образы успешно собраны и загружены в Registry

## Устранение проблем

Если по-прежнему возникает ошибка "Username and password required":

1. Убедитесь, что все секреты добавлены точно с теми же названиями
2. Проверьте права доступа токенов к Registry
3. Для GitHub Container Registry убедитесь, что токен имеет права `write:packages`
4. Для приватных репозиториев убедитесь в правильности настройки прав доступа
