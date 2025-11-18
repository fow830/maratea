import type { FastifyPluginAsync } from 'fastify';

export const healthCheckRoutes: FastifyPluginAsync = async (fastify) => {
  // Basic health check
  fastify.get('/health', async () => {
    return {
      status: 'healthy',
      service: 'api-gateway',
      timestamp: new Date().toISOString(),
    };
  });

  // Readiness probe
  fastify.get('/health/ready', async (_request, reply) => {
    // Check dependencies (Redis, etc.)
    const isReady = true; // TODO: Add actual dependency checks

    if (!isReady) {
      return reply.status(503).send({
        status: 'not ready',
        service: 'api-gateway',
        timestamp: new Date().toISOString(),
      });
    }

    return {
      status: 'ready',
      service: 'api-gateway',
      timestamp: new Date().toISOString(),
    };
  });

  // Liveness probe
  fastify.get('/health/live', async () => {
    return {
      status: 'alive',
      service: 'api-gateway',
      timestamp: new Date().toISOString(),
    };
  });
};
