# 🧪 Локальное тестирование

Инструкции для быстрого тестирования проекта на локальной машине.

## ⚡ Быстрый тест (без Telegram бота)

### 1. Установка и запуск

```bash
# Установка зависимостей
pnpm install

# Копирование конфигурации
cp env.example .env

# Запуск dev серверов
pnpm dev
```

### 2. Проверка сервисов

```bash
# API Health Check
curl http://localhost:3001/health

# Web App
open http://localhost:3000
```

**Ожидаемые результаты:**
- ✅ API возвращает `{"status":"ok"}`
- ✅ Web App открывается в браузере
- ✅ Отображается "Пользователь не определён" (это нормально без Telegram)

## 🤖 Полное тестирование с Telegram

### 1. Настройка Telegram бота

```bash
# 1. Создайте бота в Telegram
# Отправьте @BotFather команду: /newbot

# 2. Получите токен бота и добавьте в .env
BOT_TOKEN=1234567890:AABBCCDDEEFFgghhiijjkkllmmnnooppqqr

# 3. Добавьте webhook secret
WEBHOOK_SECRET=your_random_secret_32_characters
```

### 2. Настройка Supabase

```bash
# 1. Создайте проект на https://supabase.com
# 2. Добавьте в .env:
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# 3. Запустите миграции
pnpm --filter api db:migrate
```

### 3. Тестирование с ngrok

```bash
# Установите ngrok (если не установлен)
# https://ngrok.com/download

# Запустите проект
pnpm dev

# В новом терминале запустите ngrok
ngrok http 3001

# Скопируйте HTTPS URL (например: https://abc123.ngrok.io)
# Обновите .env:
WEBHOOK_URL=https://abc123.ngrok.io/webhook

# Установите webhook
curl -X POST "http://localhost:3001/api/webhook/set"
```

### 4. Настройка команд бота

Отправьте @BotFather следующие команды:

```
/setcommands
start - Запустить Mini App

/setmenubutton
url - https://abc123.ngrok.io
text - Открыть приложение
```

### 5. Тестирование

1. **Отправьте боту `/start`**
   - Должна появиться кнопка "🚀 Открыть Mini App"

2. **Нажмите кнопку Mini App**
   - Должно открыться приложение
   - Отобразится информация о пользователе
   - Кнопка "🏓 Ping API" должна работать

3. **Протестируйте API**
   - Нажмите "🏓 Ping API"
   - Должен прийти ответ с информацией о пользователе

## 🐳 Тестирование с Docker

### 1. Локальная сборка

```bash
# Сборка образов
docker-compose -f docker-compose.dev.yml build

# Запуск в Docker
docker-compose -f docker-compose.dev.yml up -d

# Проверка логов
docker-compose -f docker-compose.dev.yml logs -f
```

### 2. Проверка сервисов

```bash
# API Health Check
curl http://localhost:3001/health

# Web App
open http://localhost:3000
```

## 📊 Мониторинг и отладка

### Просмотр логов

```bash
# API логи
pnpm --filter api dev

# Web логи
pnpm --filter web dev

# Docker логи
docker-compose -f docker-compose.dev.yml logs api
docker-compose -f docker-compose.dev.yml logs web
```

### Проверка базы данных

```bash
# Статус миграций
pnpm --filter api db:status

# Добавление тестовых данных
pnpm --filter api db:seed
```

### Отладка webhook

```bash
# Информация о webhook
curl http://localhost:3001/api/webhook/info

# Удаление webhook (для сброса)
curl -X DELETE "http://localhost:3001/api/webhook"

# Повторная установка
curl -X POST "http://localhost:3001/api/webhook/set"
```

## 🔧 Полезные команды

### Разработка

```bash
# Проверка типов
pnpm type-check

# Линтинг
pnpm lint

# Форматирование
pnpm format

# Сборка
pnpm build

# Очистка
pnpm clean
```

### Отладка

```bash
# Проверка готовности проекта
./scripts/check-project.sh

# Проверка переменных окружения
cat .env

# Проверка портов
lsof -i :3000  # Web
lsof -i :3001  # API
```

## 🚨 Частые проблемы

### 1. Порты заняты

```bash
# Найти процессы на портах
lsof -i :3000
lsof -i :3001

# Убить процесс
kill -9 <PID>
```

### 2. Проблемы с pnpm

```bash
# Очистка кэша
pnpm store prune

# Переустановка
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

### 3. Ошибки TypeScript

```bash
# Проверка конфигурации
pnpm type-check

# Принудительная перекомпиляция
rm -rf apps/*/dist
pnpm build
```

### 4. Webhook не работает

```bash
# Проверьте, что ngrok запущен
curl https://your-ngrok-url.ngrok.io/health

# Проверьте webhook в Telegram
curl http://localhost:3001/api/webhook/info

# Переустановите webhook
curl -X POST "http://localhost:3001/api/webhook/set"
```

## ✅ Чек-лист готовности

- [ ] Node.js 18+ установлен
- [ ] pnpm установлен
- [ ] Зависимости установлены (`pnpm install`)
- [ ] `.env` настроен
- [ ] Supabase проект создан
- [ ] Telegram бот создан
- [ ] ngrok настроен (для тестирования)
- [ ] Миграции выполнены
- [ ] API отвечает на `/health`
- [ ] Web app открывается
- [ ] Telegram бот отвечает на `/start`
- [ ] Mini App открывается в Telegram
- [ ] API ping работает

## 🎯 Критерии успеха

После выполнения всех шагов вы должны получить:

1. **Telegram бот**, который:
   - ✅ Отвечает на команду `/start`
   - ✅ Показывает кнопку "🚀 Открыть Mini App"

2. **Mini App**, которое:
   - ✅ Открывается в Telegram
   - ✅ Показывает информацию о пользователе
   - ✅ Успешно выполняет ping API
   - ✅ Сохраняет данные в Supabase

3. **API**, которое:
   - ✅ Возвращает health status
   - ✅ Обрабатывает webhook от Telegram
   - ✅ Валидирует initData
   - ✅ Работает с базой данных

---

**🎉 Готово! Теперь вы можете переходить к production деплою!**

Следующий шаг: [Production деплой](.github/DEPLOYMENT.md)
