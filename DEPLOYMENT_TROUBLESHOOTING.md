# Руководство по устранению проблем деплоя

## 🚨 Проблема: Приложение и API недоступны после деплоя

### Основные причины и решения

#### 1. 🔐 Отсутствие SSL сертификатов
**Проблема**: Nginx ожидает HTTPS сертификаты, но они не настроены.

**Решение**:
```bash
# Настройка Let's Encrypt сертификатов
./infra/scripts/certbot-init.sh your-api-domain.com your-app-domain.com your-email@example.com

# Или временное использование HTTP для тестирования
./infra/scripts/fix-deployment.sh
```

#### 2. ⚙️ Неправильные переменные окружения
**Проблема**: Отсутствуют или неверно заданы обязательные переменные.

**Решение**:
```bash
# Создать .env файл из примера
cp env.example .env

# Отредактировать и заполнить все переменные:
# - API_DOMAIN
# - APP_DOMAIN  
# - BOT_TOKEN
# - WEBHOOK_SECRET
# - SUPABASE_URL
# - SUPABASE_SERVICE_ROLE_KEY
# - REGISTRY
# - PROJECT_SLUG
```

#### 3. 📝 Отсутствие конфигурационных файлов nginx
**Проблема**: Не созданы файлы `api.conf` и `web.conf` из шаблонов.

**Решение**:
```bash
# Создать конфигурационные файлы
mkdir -p infra/nginx/conf.d
envsubst '${API_DOMAIN} ${APP_DOMAIN}' < infra/nginx/conf.d/api.conf.template > infra/nginx/conf.d/api.conf
envsubst '${API_DOMAIN} ${APP_DOMAIN}' < infra/nginx/conf.d/web.conf.template > infra/nginx/conf.d/web.conf
```

#### 4. 🐳 Проблемы с контейнерами
**Проблема**: Контейнеры не запускаются или падают.

**Диагностика**:
```bash
# Проверить статус
docker-compose -f docker-compose.prod.yml ps

# Посмотреть логи
docker-compose -f docker-compose.prod.yml logs -f
```

### 🛠️ Быстрые инструменты для диагностики

#### Комплексная диагностика
```bash
./infra/scripts/troubleshoot.sh
```
Этот скрипт проверит:
- Статус контейнеров
- Логи сервисов  
- Сетевую связность
- SSL сертификаты
- Переменные окружения
- Внешнюю доступность

#### Автоматическое исправление
```bash
./infra/scripts/fix-deployment.sh
```
Этот скрипт:
- Проверит переменные окружения
- Создаст конфигурационные файлы nginx
- Предложит настройку SSL или временный HTTP
- Перезапустит сервисы
- Выполнит health check'и

### 🔍 Пошаговая диагностика

#### Шаг 1: Проверить переменные окружения
```bash
# Убедиться, что файл .env существует и заполнен
cat .env

# Или создать из примера
cp env.example .env
```

#### Шаг 2: Проверить статус контейнеров
```bash
docker-compose -f docker-compose.prod.yml ps
```

#### Шаг 3: Посмотреть логи
```bash
# Все логи
docker-compose -f docker-compose.prod.yml logs

# Логи конкретного сервиса
docker-compose -f docker-compose.prod.yml logs nginx
docker-compose -f docker-compose.prod.yml logs api
docker-compose -f docker-compose.prod.yml logs web
```

#### Шаг 4: Проверить внутренние health check'и
```bash
# API health check
curl http://localhost:3001/health

# Web health check  
curl http://localhost:8080/health
```

#### Шаг 5: Проверить внешнюю доступность
```bash
# Через HTTP (если SSL не настроен)
curl http://your-api-domain.com/health
curl http://your-app-domain.com

# Через HTTPS (если SSL настроен)
curl https://your-api-domain.com/health
curl https://your-app-domain.com
```

### 📋 Типичные сценарии

#### Сценарий 1: SSL не настроен
```bash
# Симптомы: контейнеры запущены, но 502/503 ошибки
# Решение:
./infra/scripts/fix-deployment.sh
# Выбрать вариант 1 для Let's Encrypt или 2 для временного HTTP
```

#### Сценарий 2: Неправильные переменные окружения
```bash
# Симптомы: контейнеры не запускаются или падают
# Решение:
cp env.example .env
# Отредактировать .env файл
./infra/scripts/fix-deployment.sh
```

#### Сценарий 3: DNS не настроен
```bash
# Симптомы: домены не резолвятся или указывают не на ваш сервер
# Проверить:
dig your-api-domain.com
dig your-app-domain.com
# Настроить A-записи в DNS провайдере
```

### 🆘 Если ничего не помогает

1. **Полная перезагрузка**:
```bash
docker-compose -f docker-compose.prod.yml down
docker system prune -f
./infra/scripts/fix-deployment.sh
```

2. **Проверить firewall**:
```bash
# Ubuntu/Debian
sudo ufw status
sudo ufw allow 80
sudo ufw allow 443

# CentOS/RHEL
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

3. **Проверить, что порты не заняты**:
```bash
netstat -tuln | grep :80
netstat -tuln | grep :443
```

### 📞 Получение помощи

При обращении за помощью приложите:
1. Вывод `./infra/scripts/troubleshoot.sh`
2. Логи: `docker-compose -f docker-compose.prod.yml logs`  
3. Переменные окружения (без секретных данных)
4. Информацию о сервере и DNS настройках

---

**💡 Совет**: Используйте скрипт `fix-deployment.sh` для быстрого исправления большинства проблем!
