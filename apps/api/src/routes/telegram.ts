import { FastifyPluginAsync } from 'fastify'
import { Telegraf } from 'telegraf'
import crypto from 'crypto'

interface TelegramRoutesOptions {
  bot: Telegraf
  webhookSecret: string
}

export const telegramRoutes: FastifyPluginAsync<TelegramRoutesOptions> = async (
  fastify,
  options
) => {
  const { bot, webhookSecret } = options

  // Webhook endpoint for Telegram
  fastify.post('/webhook', async (request, reply) => {
    try {
      // Verify webhook secret
      const signature = request.headers['x-telegram-bot-api-secret-token']
      
      if (signature !== webhookSecret) {
        return reply.status(401).send({ error: 'Invalid webhook secret' })
      }

      // Process update
      await bot.handleUpdate(request.body as any)
      reply.send({ ok: true })
    } catch (error) {
      console.error('Webhook error:', error)
      reply.status(500).send({ error: 'Internal server error' })
    }
  })

  // Set webhook endpoint (for development/setup)
  fastify.post('/api/webhook/set', async (request, reply) => {
    try {
      const webhookUrl = process.env.WEBHOOK_URL!
      
      const result = await bot.telegram.setWebhook(webhookUrl, {
        secret_token: webhookSecret,
        allowed_updates: ['message', 'callback_query', 'inline_query']
      })

      reply.send({
        success: result,
        webhook_url: webhookUrl,
        message: 'Webhook set successfully'
      })
    } catch (error) {
      console.error('Set webhook error:', error)
      reply.status(500).send({
        error: 'Failed to set webhook',
        details: error instanceof Error ? error.message : 'Unknown error'
      })
    }
  })

  // Get webhook info (for debugging)
  fastify.get('/api/webhook/info', async (request, reply) => {
    try {
      const info = await bot.telegram.getWebhookInfo()
      reply.send(info)
    } catch (error) {
      console.error('Get webhook info error:', error)
      reply.status(500).send({
        error: 'Failed to get webhook info',
        details: error instanceof Error ? error.message : 'Unknown error'
      })
    }
  })

  // Delete webhook (for development)
  fastify.delete('/api/webhook', async (request, reply) => {
    try {
      const result = await bot.telegram.deleteWebhook()
      reply.send({
        success: result,
        message: 'Webhook deleted successfully'
      })
    } catch (error) {
      console.error('Delete webhook error:', error)
      reply.status(500).send({
        error: 'Failed to delete webhook',
        details: error instanceof Error ? error.message : 'Unknown error'
      })
    }
  })
}
