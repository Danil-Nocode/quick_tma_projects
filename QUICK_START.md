# ⚡ Быстрый старт

## 🚀 5-минутная настройка

### 1. Клонирование и установка
```bash
git clone https://github.com/your-repo/quickstart-telegram-miniapp-supabase.git
cd quickstart-telegram-miniapp-supabase
pnpm install
```

### 2. Настройка Telegram Bot
```bash
# 1. Создайте бота через @BotFather в Telegram
# 2. Получите BOT_TOKEN
# 3. Установите команды бота:
```

Команды для @BotFather:
```
/setcommands
start - Запустить Mini App
```

### 3. Настройка Supabase
```bash
# 1. Создайте проект на supabase.com
# 2. Скопируйте URL и ключи API
# 3. Запустите миграции:
pnpm --filter api db:migrate
```

### 4. Локальный запуск
```bash
# Скопируйте конфиг
cp env.example .env

# Отредактируйте .env файл с вашими данными
nano .env

# Запуск в dev режиме
pnpm dev
```

Откройте:
- API: http://localhost:3001/health
- Web App: http://localhost:3000

### 5. Тестирование
```bash
# Проверка API
curl http://localhost:3001/api/health

# Проверка типов
pnpm type-check

# Линтинг
pnpm lint
```

## 🌐 Продакшн деплой

### Подготовка
```bash
# 1. Подготовьте VPS сервер
# 2. Настройте DNS записи для доменов
# 3. Добавьте GitHub Secrets (см. .github/DEPLOYMENT.md)
```

### Деплой
```bash
# Автоматический деплой через GitHub Actions
git add .
git commit -m "Deploy to production"
git push origin main
```

### Проверка
```bash
# После деплоя проверьте:
curl https://your-api-domain.com/health
curl https://your-app-domain.com/health
```

## 🔧 Основные команды

### Разработка
```bash
pnpm dev              # Запуск всех сервисов
pnpm build            # Сборка всех приложений
pnpm type-check       # Проверка типов
pnpm lint             # Линтинг кода
```

### База данных
```bash
pnpm --filter api db:migrate    # Миграции
pnpm --filter api db:seed       # Заполнение данными
pnpm --filter api db:status     # Статус БД
```

### Docker
```bash
pnpm docker:build     # Сборка образов
pnpm docker:up        # Запуск контейнеров
pnpm docker:down      # Остановка контейнеров
```

### Деплой
```bash
./infra/scripts/deploy.sh         # Ручной деплой
./infra/scripts/backup.sh         # Создание бэкапа
```

## 📱 Тестирование Mini App

1. **Локально**: Откройте http://localhost:3000
2. **В Telegram**: Отправьте `/start` боту → нажмите кнопку
3. **Проверьте функции**:
   - Отображение пользователя
   - Кнопка "Ping API"
   - Сохранение в Supabase

## ❓ Часто задаваемые вопросы

**Q: Как изменить домены?**
```bash
# Обновите переменные в .env и GitHub Secrets
API_DOMAIN=new-api.com
APP_DOMAIN=new-app.com
```

**Q: Как добавить новые команды бота?**
```bash
# Отредактируйте apps/api/src/index.ts
bot.command('help', (ctx) => {
  ctx.reply('Помощь по боту...')
})
```

**Q: Как добавить новые API endpoint?**
```bash
# Создайте новый файл в apps/api/src/routes/
# Подключите в apps/api/src/index.ts
```

**Q: Webhook не работает?**
```bash
# Проверьте webhook
curl https://your-api.com/api/webhook/info

# Переустановите
curl -X POST "https://your-api.com/api/webhook/set"
```

## 🆘 Помощь

- 📖 [Полная документация](README.md)
- 🚀 [Гайд по деплою](.github/DEPLOYMENT.md)
- 🐛 [Сообщить об ошибке](https://github.com/your-repo/issues)

---

**💡 Совет**: Начните с локальной разработки, затем переходите к продакшн деплою!
