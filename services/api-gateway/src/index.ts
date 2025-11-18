import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import { logger } from '@maratea/shared';
import { initializeOpenTelemetry } from '@maratea/shared';
import Fastify from 'fastify';
import { routes } from './config/routes';
import { errorHandler } from './handlers/error';
import { proxyHandler } from './handlers/proxy';
import { requestIdPlugin } from './plugins/request-id';
import { healthCheckRoutes } from './routes/health';

const PORT = Number(process.env.PORT) || 8080;
const HOST = process.env.HOST || '0.0.0.0';

// Initialize OpenTelemetry
initializeOpenTelemetry('api-gateway');

async function buildServer() {
  const server = Fastify({
    logger: logger.child({ service: 'api-gateway' }),
    requestIdLogLabel: 'requestId',
    genReqId: () => crypto.randomUUID(),
  });

  // Register plugins
  await server.register(cors, {
    origin: (origin, cb) => {
      const allowedOrigins = process.env.ALLOWED_ORIGINS
        ? process.env.ALLOWED_ORIGINS.split(',')
        : [
            'http://localhost:3000',
            'http://localhost:3001',
            'https://app.maratea.com',
            'https://maratea.com',
          ];

      // Allow requests with no origin (mobile apps, Postman, etc.)
      if (!origin) {
        return cb(null, true);
      }

      if (allowedOrigins.includes(origin)) {
        return cb(null, true);
      }

      return cb(new Error('Not allowed by CORS'), false);
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID'],
  });

  await server.register(rateLimit, {
    max: 100,
    timeWindow: '1 minute',
    redis: process.env.REDIS_URL
      ? new (await import('ioredis')).default(process.env.REDIS_URL)
      : undefined,
  });

  await server.register(requestIdPlugin);

  // Health check routes
  await server.register(healthCheckRoutes);

  // Proxy routes
  for (const route of routes) {
    server.all(`${route.path}/*`, async (request, reply) => {
      return proxyHandler(request, reply, route);
    });
  }

  // Error handler
  server.setErrorHandler(errorHandler);

  return server;
}

async function start() {
  try {
    const server = await buildServer();
    await server.listen({ port: PORT, host: HOST });
    logger.info(`API Gateway started on http://${HOST}:${PORT}`);
  } catch (err) {
    logger.error(err, 'Error starting server');
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

start();
