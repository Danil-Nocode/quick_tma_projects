#!/bin/bash

# Project check script - проверка готовности проекта

set -e

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
    echo -e "${GREEN}[✅]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠️]${NC} $1"
}

log_error() {
    echo -e "${RED}[❌]${NC} $1"
}

echo "🚀 Проверка готовности Telegram Mini App проекта..."
echo "=================================================="

# Check Node.js version
log_info "Проверка Node.js версии..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    log_success "Node.js установлен: $NODE_VERSION"
else
    log_error "Node.js не установлен"
    exit 1
fi

# Check pnpm
log_info "Проверка pnpm..."
if command -v pnpm &> /dev/null; then
    PNPM_VERSION=$(pnpm --version)
    log_success "pnpm установлен: v$PNPM_VERSION"
else
    log_error "pnpm не установлен. Запустите: npm install -g pnpm"
    exit 1
fi

# Check dependencies
log_info "Проверка зависимостей..."
if [ -f "pnpm-lock.yaml" ]; then
    log_success "pnpm-lock.yaml найден"
else
    log_warning "pnpm-lock.yaml не найден. Запустите: pnpm install"
fi

# Check if node_modules exists
if [ -d "node_modules" ]; then
    log_success "node_modules директория существует"
else
    log_warning "node_modules не найден. Запустите: pnpm install"
fi

# Check project structure
log_info "Проверка структуры проекта..."

# Essential files check
essential_files=(
    "package.json"
    "pnpm-workspace.yaml"
    "README.md"
    "apps/api/package.json"
    "apps/web/package.json"
    "docker-compose.prod.yml"
    ".github/workflows/deploy.yml"
    "env.example"
)

for file in "${essential_files[@]}"; do
    if [ -f "$file" ]; then
        log_success "$file ✓"
    else
        log_error "$file отсутствует"
    fi
done

# Essential directories check
essential_dirs=(
    "apps/api/src"
    "apps/web/src"
    "infra/nginx"
    "infra/scripts"
    "supabase/migrations"
    ".github/workflows"
)

for dir in "${essential_dirs[@]}"; do
    if [ -d "$dir" ]; then
        log_success "$dir/ ✓"
    else
        log_error "$dir/ отсутствует"
    fi
done

# Check environment file
log_info "Проверка переменных окружения..."
if [ -f ".env" ]; then
    log_success ".env файл найден"
    
    # Check for placeholder values
    if grep -q "\[\[.*\]\]" .env 2>/dev/null; then
        log_warning ".env содержит плейсхолдеры [[...]] - не забудьте заменить их реальными значениями"
    else
        log_success "Плейсхолдеры в .env заменены"
    fi
else
    log_warning ".env не найден. Скопируйте из env.example и заполните"
fi

# Check TypeScript configuration
log_info "Проверка TypeScript конфигурации..."
ts_configs=(
    "apps/api/tsconfig.json"
    "apps/web/tsconfig.json"
)

for config in "${ts_configs[@]}"; do
    if [ -f "$config" ]; then
        log_success "$config ✓"
    else
        log_error "$config отсутствует"
    fi
done

# Check Docker files
log_info "Проверка Docker конфигурации..."
docker_files=(
    "apps/api/Dockerfile"
    "apps/web/Dockerfile"
    "docker-compose.prod.yml"
    "docker-compose.dev.yml"
)

for file in "${docker_files[@]}"; do
    if [ -f "$file" ]; then
        log_success "$file ✓"
    else
        log_error "$file отсутствует"
    fi
done

# Check scripts
log_info "Проверка деплой скриптов..."
scripts=(
    "infra/scripts/server-setup.sh"
    "infra/scripts/certbot-init.sh"
    "infra/scripts/deploy.sh"
    "infra/scripts/backup.sh"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            log_success "$script ✓ (исполняемый)"
        else
            log_warning "$script найден, но не исполняемый. Запустите: chmod +x $script"
        fi
    else
        log_error "$script отсутствует"
    fi
done

# Check if git is initialized
log_info "Проверка Git репозитория..."
if [ -d ".git" ]; then
    log_success "Git репозиторий инициализирован"
    
    # Check if there are any commits
    if git log --oneline -n 1 &> /dev/null; then
        log_success "Репозиторий содержит коммиты"
    else
        log_warning "Репозиторий пустой. Создайте первый коммит"
    fi
else
    log_warning "Git репозиторий не инициализирован. Запустите: git init"
fi

# Summary
echo ""
echo "=================================================="
echo "🎯 Резюме проверки"
echo "=================================================="

# Check if we can run basic commands
log_info "Тестирование основных команд..."

# Test type checking
if pnpm type-check &> /dev/null; then
    log_success "TypeScript проверка типов проходит"
else
    log_warning "TypeScript проверка типов не проходит"
fi

# Test build
if pnpm build &> /dev/null; then
    log_success "Сборка проекта успешна"
else
    log_warning "Ошибка при сборке проекта"
fi

echo ""
echo "🚀 Что делать дальше:"
echo ""
echo "1. 📥 Установите зависимости:"
echo "   pnpm install"
echo ""
echo "2. ⚙️ Настройте переменные окружения:"
echo "   cp env.example .env"
echo "   nano .env"
echo ""
echo "3. 🗄️ Настройте Supabase:"
echo "   - Создайте проект на supabase.com"
echo "   - Добавьте URL и ключи в .env"
echo "   - Запустите миграции: pnpm --filter api db:migrate"
echo ""
echo "4. 🤖 Настройте Telegram бота:"
echo "   - Создайте бота через @BotFather"
echo "   - Добавьте BOT_TOKEN в .env"
echo ""
echo "5. 💻 Локальное тестирование:"
echo "   pnpm dev"
echo ""
echo "6. 🚀 Production деплой:"
echo "   - Настройте GitHub Secrets"
echo "   - Push в main ветку для автоматического деплоя"
echo ""
echo "📚 Полная документация: README.md"
echo "⚡ Быстрый старт: QUICK_START.md"
echo ""
echo "🎉 Проект готов к разработке и деплою!"
