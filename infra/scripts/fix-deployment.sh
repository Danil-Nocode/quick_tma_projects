#!/bin/bash

# Quick fix script for common deployment issues
# Скрипт быстрого исправления проблем деплоя

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🔧 Telegram Mini App - Исправление проблем деплоя"
echo "=================================================="
echo ""

# Check if we're in the project root
if [ ! -f "docker-compose.prod.yml" ]; then
    log_error "Пожалуйста, запустите скрипт из корневой директории проекта"
    exit 1
fi

# Load environment variables
if [ -f ".env.production" ]; then
    log_info "Загружаем переменные окружения из .env.production"
    set -a
    source .env.production
    set +a
elif [ -f ".env" ]; then
    log_info "Загружаем переменные окружения из .env"
    set -a
    source .env
    set +a
else
    log_warning "Файл переменных окружения не найден"
    echo "Создайте файл .env или .env.production на основе env.example"
    read -p "Создать файл .env сейчас? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp env.example .env
        log_info "Файл .env создан. Отредактируйте его и запустите скрипт снова"
        exit 0
    else
        log_error "Переменные окружения не настроены"
        exit 1
    fi
fi

# Validate required environment variables
required_vars=(
    "API_DOMAIN"
    "APP_DOMAIN"
    "BOT_TOKEN"
    "WEBHOOK_SECRET"
    "SUPABASE_URL"
    "SUPABASE_SERVICE_ROLE_KEY"
    "REGISTRY"
    "PROJECT_SLUG"
)

log_info "1. Проверка переменных окружения..."
missing_vars=()
for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    log_error "Отсутствуют обязательные переменные окружения:"
    for var in "${missing_vars[@]}"; do
        echo "  - $var"
    done
    log_error "Настройте переменные окружения в файле .env и запустите скрипт снова"
    exit 1
fi

log_success "Все переменные окружения настроены"

# Create nginx configurations from templates
log_info "2. Создание конфигурационных файлов nginx..."
mkdir -p infra/nginx/conf.d

if envsubst '${API_DOMAIN} ${APP_DOMAIN}' < infra/nginx/conf.d/api.conf.template > infra/nginx/conf.d/api.conf; then
    log_success "Создан файл infra/nginx/conf.d/api.conf"
else
    log_error "Не удалось создать api.conf"
    exit 1
fi

if envsubst '${API_DOMAIN} ${APP_DOMAIN}' < infra/nginx/conf.d/web.conf.template > infra/nginx/conf.d/web.conf; then
    log_success "Создан файл infra/nginx/conf.d/web.conf"
else
    log_error "Не удалось создать web.conf"
    exit 1
fi

# Check SSL certificates
log_info "3. Проверка SSL сертификатов..."
ssl_missing=false

if [ ! -d "infra/ssl/$API_DOMAIN" ] || [ ! -f "infra/ssl/$API_DOMAIN/fullchain.pem" ]; then
    log_warning "SSL сертификаты для $API_DOMAIN не найдены"
    ssl_missing=true
fi

if [ ! -d "infra/ssl/$APP_DOMAIN" ] || [ ! -f "infra/ssl/$APP_DOMAIN/fullchain.pem" ]; then
    log_warning "SSL сертификаты для $APP_DOMAIN не найдены"  
    ssl_missing=true
fi

if [ "$ssl_missing" = true ]; then
    echo ""
    log_warning "SSL сертификаты не найдены. Это может быть причиной недоступности приложения."
    echo ""
    echo "Варианты решения:"
    echo ""
    echo "📋 ВАРИАНТ 1: Настройка Let's Encrypt сертификатов (рекомендуется)"
    echo "   ./infra/scripts/certbot-init.sh $API_DOMAIN $APP_DOMAIN your-email@example.com"
    echo ""
    echo "📋 ВАРИАНТ 2: Временное отключение HTTPS для тестирования"
    echo "   (создаст временную конфигурацию только для HTTP)"
    echo ""
    read -p "Выберите вариант (1 для Let's Encrypt, 2 для HTTP, s для пропуска): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[1]$ ]]; then
        read -p "Введите email для Let's Encrypt: " email
        if [ -n "$email" ]; then
            log_info "Запуск настройки SSL сертификатов..."
            chmod +x infra/scripts/certbot-init.sh
            ./infra/scripts/certbot-init.sh "$API_DOMAIN" "$APP_DOMAIN" "$email"
        else
            log_warning "Email не введен, пропускаем настройку SSL"
        fi
    elif [[ $REPLY =~ ^[2]$ ]]; then
        log_info "Создание временной HTTP-конфигурации..."
        
        # Create temporary HTTP-only configs
        cat > infra/nginx/conf.d/api.conf << EOF
server {
    listen 80;
    server_name $API_DOMAIN;

    # Rate limiting for webhook
    location /webhook {
        limit_req zone=webhook burst=10 nodelay;
        
        proxy_pass http://api_backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # API routes with rate limiting
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://api_backend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://api_backend;
        proxy_set_header Host \$host;
        access_log off;
    }

    # Root redirect to app domain
    location = / {
        return 301 http://$APP_DOMAIN;
    }
}
EOF

        cat > infra/nginx/conf.d/web.conf << EOF
server {
    listen 80;
    server_name $APP_DOMAIN;

    root /usr/share/nginx/html;
    index index.html;

    # Static files caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        gzip_static on;
    }

    # Main SPA route
    location / {
        try_files \$uri \$uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://web_backend;
        proxy_set_header Host \$host;
        access_log off;
    }
}
EOF

        log_success "Временная HTTP конфигурация создана"
        log_warning "⚠️  Не забудьте настроить HTTPS для production!"
    else
        log_info "Пропуск настройки SSL"
    fi
else
    log_success "SSL сертификаты найдены"
fi

# Stop existing containers
log_info "4. Остановка существующих контейнеров..."
docker-compose -f docker-compose.prod.yml down || log_warning "Не удалось остановить контейнеры (возможно, они не запущены)"

# Pull/build images
log_info "5. Получение образов..."
docker-compose -f docker-compose.prod.yml pull || log_warning "Не удалось скачать образы, будем использовать локальные"

# Start services
log_info "6. Запуск сервисов..."
if docker-compose -f docker-compose.prod.yml up -d --remove-orphans; then
    log_success "Сервисы запущены"
else
    log_error "Не удалось запустить сервисы"
    log_info "Показываем логи для диагностики..."
    docker-compose -f docker-compose.prod.yml logs
    exit 1
fi

# Wait for services
log_info "7. Ожидание готовности сервисов..."
sleep 15

# Health checks
log_info "8. Проверка работоспособности..."

# Check API
api_healthy=false
for i in {1..10}; do
    if curl -f -s --connect-timeout 5 http://localhost:3001/health > /dev/null 2>&1; then
        log_success "✅ API здоров"
        api_healthy=true
        break
    fi
    log_info "Попытка $i/10: Ожидаем готовности API..."
    sleep 3
done

if [ "$api_healthy" = false ]; then
    log_warning "❌ API не отвечает на health check"
fi

# Check Web
web_healthy=false
for i in {1..10}; do
    if curl -f -s --connect-timeout 5 http://localhost:8080/health > /dev/null 2>&1; then
        log_success "✅ Web приложение здорово"
        web_healthy=true
        break
    fi
    log_info "Попытка $i/10: Ожидаем готовности Web..."
    sleep 3
done

if [ "$web_healthy" = false ]; then
    log_warning "❌ Web приложение не отвечает на health check"
fi

# Setup webhook if API is healthy
if [ "$api_healthy" = true ]; then
    log_info "9. Настройка Telegram webhook..."
    if curl -X POST "http://localhost:3001/api/webhook/set" \
         -H "Content-Type: application/json" \
         -f -s > /dev/null 2>&1; then
        log_success "✅ Telegram webhook настроен"
    else
        log_warning "❌ Не удалось настроить Telegram webhook"
    fi
fi

# Show final status
echo ""
echo "========================================="
echo "         🎯 Итоги исправления"
echo "========================================="

docker-compose -f docker-compose.prod.yml ps

echo ""

if [ "$api_healthy" = true ] && [ "$web_healthy" = true ]; then
    log_success "🎉 Все сервисы работают корректно!"
    echo ""
    echo "Ваше приложение доступно по адресам:"
    if [ "$ssl_missing" = false ]; then
        echo "  📱 Web App: https://$APP_DOMAIN"
        echo "  🔗 API Health: https://$API_DOMAIN/health"
    else
        echo "  📱 Web App: http://$APP_DOMAIN"
        echo "  🔗 API Health: http://$API_DOMAIN/health"
    fi
else
    log_warning "⚠️  Некоторые сервисы могут работать некорректно"
    echo ""
    echo "Для диагностики выполните:"
    echo "  ./infra/scripts/troubleshoot.sh"
    echo "  docker-compose -f docker-compose.prod.yml logs -f"
fi

echo ""
echo "📊 Мониторинг:"
echo "  docker-compose -f docker-compose.prod.yml logs -f"
echo "  docker-compose -f docker-compose.prod.yml ps"
