import { FastifyPluginAsync } from 'fastify'
import { supabase } from '../lib/supabase.js'

export const healthRoutes: FastifyPluginAsync = async (fastify) => {
  // Basic health check
  fastify.get('/health', async (request, reply) => {
    reply.send({ status: 'ok', timestamp: new Date().toISOString() })
  })

  // API health check
  fastify.get('/api/health', async (request, reply) => {
    reply.send({ status: 'ok', timestamp: new Date().toISOString() })
  })

  // Detailed health check with database connection
  fastify.get('/api/health/detailed', async (request, reply) => {
    try {
      // Test Supabase connection
      const { data, error } = await supabase
        .from('profiles')
        .select('count')
        .limit(1)

      if (error) {
        throw error
      }

      reply.send({
        status: 'ok',
        timestamp: new Date().toISOString(),
        services: {
          database: 'connected',
          api: 'running'
        }
      })
    } catch (error) {
      reply.status(503).send({
        status: 'error',
        timestamp: new Date().toISOString(),
        services: {
          database: 'disconnected',
          api: 'running'
        },
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    }
  })
}
