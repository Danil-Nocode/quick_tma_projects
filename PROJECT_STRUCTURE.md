# 📁 Структура проекта

## 🏗️ Обзор архитектуры

```
quickstart-telegram-miniapp-supabase/
├── 📱 apps/                          # Приложения
│   ├── 🤖 api/                       # Telegram Bot API + Fastify
│   └── ⚛️  web/                       # React Mini App
├── 🚀 infra/                         # Инфраструктура
│   ├── 🌐 nginx/                     # Nginx конфигурации
│   └── 📜 scripts/                   # Скрипты автоматизации
├── 🗄️ supabase/                      # База данных
│   ├── migrations/                   # SQL миграции
│   └── seed/                         # Тестовые данные
├── 🔄 .github/                       # CI/CD
│   └── workflows/                    # GitHub Actions
└── 📋 package.json                   # Монорепо конфигурация
```

## 📱 Apps - Приложения

### 🤖 API (`apps/api/`)

**Назначение**: Telegram Bot сервер на Fastify + Telegraf с webhook поддержкой

```
apps/api/
├── src/
│   ├── index.ts              # 🚀 Основной сервер
│   ├── lib/                  # 📚 Библиотеки
│   │   ├── supabase.ts       #   🗄️ Supabase клиент
│   │   └── telegram.ts       #   📱 Telegram утилиты
│   ├── routes/               # 🛣️ API маршруты
│   │   ├── health.ts         #   ❤️ Health checks
│   │   └── telegram.ts       #   🤖 Telegram webhook
│   └── scripts/              # 📜 Утилиты БД
│       ├── migrate.ts        #   🔄 Миграции
│       ├── seed.ts           #   🌱 Заполнение данными
│       └── status.ts         #   📊 Статус БД
├── Dockerfile               # 🐳 Продакшн образ
├── Dockerfile.dev           # 🛠️ Разработка образ
├── package.json             # 📦 Зависимости
├── tsconfig.json            # ⚙️ TypeScript конфиг
└── tsup.config.ts           # 📦 Сборка конфиг
```

**Основные функции:**
- ✅ Обработка Telegram webhook
- ✅ Валидация HMAC-SHA256
- ✅ CORS и rate limiting
- ✅ Интеграция с Supabase
- ✅ Health checks

### ⚛️ Web (`apps/web/`)

**Назначение**: React Mini App для Telegram с Vite

```
apps/web/
├── src/
│   ├── App.tsx               # 🏠 Главный компонент
│   ├── main.tsx             # 🚀 Точка входа
│   ├── index.css            # 🎨 Стили
│   ├── components/          # 🧩 Компоненты
│   │   ├── UserInfo.tsx     #   👤 Инфо о пользователе
│   │   └── PingSection.tsx  #   🏓 Тест API
│   └── hooks/               # 🎣 React хуки
│       └── useTelegram.ts   #   📱 Telegram WebApp API
├── public/                  # 📁 Статические файлы
├── Dockerfile              # 🐳 Продакшн образ (Nginx)
├── Dockerfile.dev          # 🛠️ Разработка образ
├── nginx.conf              # 🌐 Nginx для контейнера
├── package.json            # 📦 Зависимости
├── tsconfig.json           # ⚙️ TypeScript конфиг
├── tsconfig.node.json      # ⚙️ Node.js конфиг
└── vite.config.ts          # ⚡ Vite конфигурация
```

**Основные функции:**
- ✅ Telegram WebApp интеграция
- ✅ Чтение initData пользователя
- ✅ Адаптивный UI для Telegram
- ✅ API тестирование
- ✅ Тема Telegram

## 🚀 Infra - Инфраструктура

### 🌐 Nginx (`infra/nginx/`)

**Назначение**: Reverse proxy + SSL termination

```
infra/nginx/
├── nginx.conf                    # ⚙️ Основной конфиг
└── conf.d/                      # 📁 Конфиги доменов
    ├── api.conf.template        # 🤖 API домен шаблон
    └── web.conf.template        # ⚛️ Web домен шаблон
```

**Функции:**
- ✅ SSL терминация
- ✅ Reverse proxy для API и Web
- ✅ Rate limiting
- ✅ Security headers
- ✅ Gzip compression

### 📜 Scripts (`infra/scripts/`)

**Назначение**: Скрипты автоматизации деплоя

```
infra/scripts/
├── server-setup.sh          # 🛠️ Начальная настройка VPS
├── certbot-init.sh          # 🔒 Настройка SSL
├── deploy.sh                # 🚀 Деплой приложения
└── backup.sh                # 💾 Резервное копирование
```

**Возможности:**
- ✅ Автоматическая настройка сервера
- ✅ SSL сертификаты Let's Encrypt
- ✅ Zero-downtime deployment
- ✅ Автоматические бэкапы

## 🗄️ Supabase - База данных

```
supabase/
├── migrations/                  # 🔄 SQL миграции
│   └── 001_create_profiles.sql # 👤 Таблица пользователей
├── seed/                       # 🌱 Тестовые данные
│   └── 001_test_profiles.sql   # 👥 Тестовые пользователи
└── config.toml                 # ⚙️ Supabase конфигурация
```

**Схема БД:**
```sql
profiles (
  id UUID PRIMARY KEY,
  tg_id BIGINT UNIQUE,        -- Telegram User ID
  username TEXT,              -- @username
  first_name TEXT,            -- Имя
  last_name TEXT,             -- Фамилия
  created_at TIMESTAMPTZ,     -- Дата создания
  updated_at TIMESTAMPTZ      -- Последнее обновление
)
```

## 🔄 CI/CD - GitHub Actions

```
.github/
├── workflows/
│   └── deploy.yml          # 🚀 Основной workflow
└── DEPLOYMENT.md           # 📖 Инструкции по деплою
```

**Этапы деплоя:**
1. ✅ **Test** - Проверка кода, типов, линтинг
2. 🐳 **Build** - Сборка Docker образов
3. 📤 **Push** - Загрузка в registry
4. 🚀 **Deploy** - Деплой на VPS
5. 🔄 **Migrate** - Обновление БД
6. 🤖 **Webhook** - Настройка Telegram

## 🐳 Docker конфигурация

```
├── docker-compose.prod.yml     # 🏭 Продакшн композиция
├── docker-compose.dev.yml      # 🛠️ Разработка композиция
└── Dockerfile(s)               # 🐳 Образы приложений
```

**Сервисы:**
- `nginx` - Reverse proxy + SSL
- `api` - Telegram Bot API
- `web` - React Mini App
- `redis` - Кэш (только dev)

## 📋 Корневые файлы

```
├── package.json              # 📦 Монорепо конфигурация
├── pnpm-workspace.yaml       # 🏗️ PNPM workspaces
├── .gitignore               # 🚫 Git исключения
├── env.example              # 🔧 Пример переменных
├── README.md                # 📖 Основная документация
├── QUICK_START.md           # ⚡ Быстрый старт
├── LICENSE                  # ⚖️ MIT лицензия
└── .husky/                  # 🐺 Git hooks
    └── pre-commit           # ✅ Pre-commit проверки
```

## 🔧 Технологический стек

### Backend
- **Runtime**: Node.js 18+
- **Framework**: Fastify 4
- **Bot**: Telegraf 4
- **Database**: Supabase (PostgreSQL)
- **Language**: TypeScript
- **Build**: tsup

### Frontend
- **Framework**: React 18
- **Build**: Vite 5
- **Language**: TypeScript
- **Styling**: CSS3 + CSS Variables
- **Telegram**: WebApp API

### Infrastructure
- **Containerization**: Docker + Docker Compose
- **Reverse Proxy**: Nginx
- **SSL**: Let's Encrypt (Certbot)
- **CI/CD**: GitHub Actions
- **Registry**: GitHub Container Registry

### Development
- **Package Manager**: pnpm
- **Code Quality**: ESLint + TypeScript
- **Git Hooks**: Husky
- **Monorepo**: pnpm workspaces

## 🚀 Deployment архитектура

```
┌─────────────────────────────────────────────────────────┐
│                        Internet                          │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                   Nginx                                  │
│  ┌─────────────────────┐  ┌─────────────────────────┐   │
│  │   api.domain.com    │  │   app.domain.com        │   │
│  │   (SSL termination) │  │   (SSL termination)     │   │
│  └─────────────────────┘  └─────────────────────────┘   │
└────────────┬───────────────────────┬────────────────────┘
             │                       │
┌────────────▼────────────┐ ┌───────▼──────────────────┐
│     API Container       │ │    Web Container         │
│   (Fastify + Telegraf)  │ │   (React + Nginx)        │
│   Port: 3001            │ │   Port: 8080             │
└────────────┬────────────┘ └──────────────────────────┘
             │
┌────────────▼────────────────────────────────────────────┐
│                    Supabase                             │
│              (PostgreSQL + API)                         │
└─────────────────────────────────────────────────────────┘
```

Этот проект предоставляет полную инфраструктуру для создания production-ready Telegram Mini App с минимальными усилиями по настройке! 🎉
