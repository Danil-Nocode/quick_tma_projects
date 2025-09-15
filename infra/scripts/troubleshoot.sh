#!/bin/bash

# Troubleshooting script for Telegram Mini App deployment
# Диагностика проблем с деплоем Telegram Mini App

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

echo "🔍 Telegram Mini App - Диагностика проблем деплоя"
echo "=================================================="
echo ""

# Check if we're in the project root
if [ ! -f "docker-compose.prod.yml" ]; then
    log_error "Пожалуйста, запустите скрипт из корневой директории проекта"
    exit 1
fi

# 1. Check Docker containers status
log_info "1. Проверка статуса контейнеров Docker..."
echo ""

if docker-compose -f docker-compose.prod.yml ps; then
    log_success "Команда docker-compose выполнена успешно"
else
    log_error "Не удалось получить статус контейнеров"
    exit 1
fi

echo ""

# 2. Check container logs
log_info "2. Проверка логов контейнеров..."
echo ""

log_info "🔸 Логи Nginx:"
echo "----------------------------------------"
docker-compose -f docker-compose.prod.yml logs --tail=20 nginx || log_warning "Не удалось получить логи nginx"

echo ""
log_info "🔸 Логи API:"
echo "----------------------------------------"
docker-compose -f docker-compose.prod.yml logs --tail=20 api || log_warning "Не удалось получить логи api"

echo ""
log_info "🔸 Логи Web:"
echo "----------------------------------------"
docker-compose -f docker-compose.prod.yml logs --tail=20 web || log_warning "Не удалось получить логи web"

echo ""

# 3. Check network connectivity
log_info "3. Проверка сетевых подключений..."
echo ""

# Check if containers can reach each other
log_info "🔸 Проверка внутренней связности контейнеров:"
if docker exec tma-nginx wget -q --tries=1 --timeout=5 --spider http://api:3001/health 2>/dev/null; then
    log_success "✅ Nginx -> API: OK"
else
    log_warning "❌ Nginx -> API: Недоступно"
fi

if docker exec tma-nginx wget -q --tries=1 --timeout=5 --spider http://web:8080/health 2>/dev/null; then
    log_success "✅ Nginx -> Web: OK"
else
    log_warning "❌ Nginx -> Web: Недоступно"
fi

echo ""

# 4. Check individual container health
log_info "4. Проверка здоровья отдельных контейнеров..."
echo ""

log_info "🔸 API Health Check:"
if curl -f -s --connect-timeout 5 http://localhost:3001/health > /dev/null 2>&1; then
    log_success "✅ API health check: OK"
    API_RESPONSE=$(curl -s http://localhost:3001/health)
    echo "Response: $API_RESPONSE"
else
    log_warning "❌ API health check: Недоступно"
fi

log_info "🔸 Web Health Check:"
if curl -f -s --connect-timeout 5 http://localhost:8080/health > /dev/null 2>&1; then
    log_success "✅ Web health check: OK"
    WEB_RESPONSE=$(curl -s http://localhost:8080/health)
    echo "Response: $WEB_RESPONSE"
else
    log_warning "❌ Web health check: Недоступно"
fi

echo ""

# 5. Check SSL certificates
log_info "5. Проверка SSL сертификатов..."
echo ""

if [ -f ".env" ]; then
    source .env
elif [ -f ".env.production" ]; then
    source .env.production
fi

if [ -n "${API_DOMAIN:-}" ] && [ -n "${APP_DOMAIN:-}" ]; then
    # Check if SSL certificates exist
    if [ -d "infra/ssl/$API_DOMAIN" ]; then
        if [ -f "infra/ssl/$API_DOMAIN/fullchain.pem" ] && [ -f "infra/ssl/$API_DOMAIN/privkey.pem" ]; then
            log_success "✅ SSL сертификаты для API домена ($API_DOMAIN): Найдены"
        else
            log_warning "❌ SSL сертификаты для API домена ($API_DOMAIN): Не найдены"
        fi
    else
        log_warning "❌ Директория SSL для API домена ($API_DOMAIN): Не найдена"
    fi

    if [ -d "infra/ssl/$APP_DOMAIN" ]; then
        if [ -f "infra/ssl/$APP_DOMAIN/fullchain.pem" ] && [ -f "infra/ssl/$APP_DOMAIN/privkey.pem" ]; then
            log_success "✅ SSL сертификаты для App домена ($APP_DOMAIN): Найдены"
        else
            log_warning "❌ SSL сертификаты для App домена ($APP_DOMAIN): Не найдены"
        fi
    else
        log_warning "❌ Директория SSL для App домена ($APP_DOMAIN): Не найдена"
    fi
else
    log_warning "❌ Переменные окружения API_DOMAIN и APP_DOMAIN не заданы"
fi

echo ""

# 6. Check nginx configuration
log_info "6. Проверка конфигурации Nginx..."
echo ""

if docker exec tma-nginx nginx -t 2>/dev/null; then
    log_success "✅ Конфигурация Nginx: Корректна"
else
    log_error "❌ Конфигурация Nginx: Ошибки"
    docker exec tma-nginx nginx -t 2>&1 || true
fi

# Check if nginx config files exist
if [ -f "infra/nginx/conf.d/api.conf" ] && [ -f "infra/nginx/conf.d/web.conf" ]; then
    log_success "✅ Конфигурационные файлы Nginx: Найдены"
else
    log_warning "❌ Конфигурационные файлы Nginx: Не найдены"
    log_info "Возможно, нужно выполнить команду для их создания из templates"
fi

echo ""

# 7. Check environment variables
log_info "7. Проверка переменных окружения..."
echo ""

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

missing_vars=()
for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -eq 0 ]; then
    log_success "✅ Все обязательные переменные окружения заданы"
else
    log_warning "❌ Отсутствуют переменные окружения: ${missing_vars[*]}"
fi

echo ""

# 8. Port connectivity check
log_info "8. Проверка доступности портов..."
echo ""

# Check if ports are listening
if netstat -tuln 2>/dev/null | grep -q ":80 "; then
    log_success "✅ Порт 80: Слушает"
else
    log_warning "❌ Порт 80: Не слушает"
fi

if netstat -tuln 2>/dev/null | grep -q ":443 "; then
    log_success "✅ Порт 443: Слушает"
else
    log_warning "❌ Порт 443: Не слушает"
fi

echo ""

# 9. External connectivity check (if domains are set)
if [ -n "${API_DOMAIN:-}" ] && [ -n "${APP_DOMAIN:-}" ]; then
    log_info "9. Проверка внешней доступности..."
    echo ""
    
    log_info "🔸 Проверка HTTP редиректа на HTTPS:"
    if curl -I -s --connect-timeout 10 http://$API_DOMAIN | grep -q "301\|302"; then
        log_success "✅ HTTP -> HTTPS редирект для API: Работает"
    else
        log_warning "❌ HTTP -> HTTPS редирект для API: Не работает"
    fi
    
    if curl -I -s --connect-timeout 10 http://$APP_DOMAIN | grep -q "301\|302"; then
        log_success "✅ HTTP -> HTTPS редирект для App: Работает"
    else
        log_warning "❌ HTTP -> HTTPS редирект для App: Не работает"
    fi
    
    log_info "🔸 Проверка HTTPS доступности:"
    if curl -f -s --connect-timeout 10 https://$API_DOMAIN/health > /dev/null 2>&1; then
        log_success "✅ HTTPS API ($API_DOMAIN): Доступно"
    else
        log_warning "❌ HTTPS API ($API_DOMAIN): Недоступно"
    fi
    
    if curl -f -s --connect-timeout 10 https://$APP_DOMAIN/ > /dev/null 2>&1; then
        log_success "✅ HTTPS App ($APP_DOMAIN): Доступно"
    else
        log_warning "❌ HTTPS App ($APP_DOMAIN): Недоступно"
    fi
fi

echo ""
echo "=================================================="
echo "🎯 Краткий итог диагностики:"
echo "=================================================="

# Summary
echo "📋 Для исправления проблем выполните следующие действия:"
echo ""

if [ ${#missing_vars[@]} -gt 0 ]; then
    echo "1. ⚠️  Настройте отсутствующие переменные окружения:"
    for var in "${missing_vars[@]}"; do
        echo "   - $var"
    done
    echo ""
fi

if [ ! -f "infra/nginx/conf.d/api.conf" ] || [ ! -f "infra/nginx/conf.d/web.conf" ]; then
    echo "2. 🔧 Создайте конфигурационные файлы nginx:"
    echo "   envsubst '\${API_DOMAIN} \${APP_DOMAIN}' < infra/nginx/conf.d/api.conf.template > infra/nginx/conf.d/api.conf"
    echo "   envsubst '\${API_DOMAIN} \${APP_DOMAIN}' < infra/nginx/conf.d/web.conf.template > infra/nginx/conf.d/web.conf"
    echo ""
fi

if [ -n "${API_DOMAIN:-}" ] && [ -n "${APP_DOMAIN:-}" ]; then
    if [ ! -d "infra/ssl/$API_DOMAIN" ] || [ ! -d "infra/ssl/$APP_DOMAIN" ]; then
        echo "3. 🔐 Настройте SSL сертификаты:"
        echo "   ./infra/scripts/certbot-init.sh $API_DOMAIN $APP_DOMAIN your-email@example.com"
        echo ""
    fi
fi

echo "4. 🔄 Перезапустите сервисы:"
echo "   docker-compose -f docker-compose.prod.yml down"
echo "   docker-compose -f docker-compose.prod.yml up -d"
echo ""

echo "5. 📊 Мониторинг логов:"
echo "   docker-compose -f docker-compose.prod.yml logs -f"
echo ""

echo "🆘 Если проблемы продолжаются, проверьте:"
echo "   - DNS записи доменов указывают на сервер"
echo "   - Firewall не блокирует порты 80/443"
echo "   - Образы Docker собраны корректно"

echo ""
echo "🎉 Готово! Используйте эту информацию для устранения проблем."
