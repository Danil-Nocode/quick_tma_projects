import 'dotenv/config'
import Fastify from 'fastify'
import helmet from '@fastify/helmet'
import cors from '@fastify/cors'
import rateLimit from '@fastify/rate-limit'
import { Telegraf } from 'telegraf'
import { supabase } from './lib/supabase.js'
import { validateTelegramWebAppData } from './lib/telegram.js'
import { healthRoutes } from './routes/health.js'
import { telegramRoutes } from './routes/telegram.js'

const PORT = Number(process.env.PORT) || 3001
const BOT_TOKEN = process.env.BOT_TOKEN!
const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET!
const APP_DOMAIN = process.env.APP_DOMAIN!

if (!BOT_TOKEN || !WEBHOOK_SECRET || !APP_DOMAIN) {
  console.error('Missing required environment variables')
  process.exit(1)
}

const fastify = Fastify({
  logger: process.env.NODE_ENV === 'development'
})

// Security middleware
await fastify.register(helmet)
await fastify.register(cors, {
  origin: [
    `https://${APP_DOMAIN}`,
    // Allow localhost for development
    'http://localhost:3000',
    'http://127.0.0.1:3000'
  ],
  credentials: true
})

await fastify.register(rateLimit, {
  max: 100,
  timeWindow: '1 minute'
})

// Initialize Telegram bot
const bot = new Telegraf(BOT_TOKEN)

// Bot commands
bot.start((ctx) => {
  const webAppUrl = `https://${APP_DOMAIN}`
  
  ctx.reply('👋 Добро пожаловать! Нажмите кнопку ниже, чтобы открыть Mini App:', {
    reply_markup: {
      inline_keyboard: [[
        {
          text: '🚀 Открыть Mini App',
          web_app: { url: webAppUrl }
        }
      ]]
    }
  })
})

// Register routes
await fastify.register(healthRoutes)
await fastify.register(telegramRoutes, { bot, webhookSecret: WEBHOOK_SECRET })

// API ping route with Telegram data validation
fastify.post<{
  Body: {
    initData: string
  }
}>('/api/ping', async (request, reply) => {
  try {
    const { initData } = request.body
    
    if (!initData) {
      return reply.status(400).send({ error: 'initData is required' })
    }

    const userData = validateTelegramWebAppData(initData, BOT_TOKEN)
    
    if (!userData) {
      return reply.status(401).send({ error: 'Invalid Telegram data' })
    }

    // Save or update user in Supabase
    const { data: existingUser } = await supabase
      .from('profiles')
      .select('*')
      .eq('tg_id', userData.user.id)
      .single()

    if (!existingUser) {
      await supabase
        .from('profiles')
        .insert({
          tg_id: userData.user.id,
          username: userData.user.username || null,
          first_name: userData.user.first_name || null,
          last_name: userData.user.last_name || null
        })
    } else {
      await supabase
        .from('profiles')
        .update({
          username: userData.user.username || null,
          first_name: userData.user.first_name || null,
          last_name: userData.user.last_name || null,
          updated_at: new Date().toISOString()
        })
        .eq('tg_id', userData.user.id)
    }

    reply.send({
      status: 'ok',
      message: 'Pong! 🏓',
      user: userData.user,
      timestamp: new Date().toISOString()
    })
  } catch (error) {
    console.error('Ping error:', error)
    reply.status(500).send({ error: 'Internal server error' })
  }
})

// Graceful shutdown
const signals = ['SIGTERM', 'SIGINT']
signals.forEach(signal => {
  process.on(signal, async () => {
    console.log(`Received ${signal}, shutting down gracefully...`)
    await fastify.close()
    process.exit(0)
  })
})

try {
  await fastify.listen({ port: PORT, host: '0.0.0.0' })
  console.log(`🚀 Server running on port ${PORT}`)
} catch (err) {
  fastify.log.error(err)
  process.exit(1)
}
