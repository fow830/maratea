import { logger } from '@maratea/shared';
import type { FastifyReply, FastifyRequest } from 'fastify';
import CircuitBreaker from 'opossum';
import type { RouteConfig } from '../config/routes';
import {
  recordProxyRequest,
  recordCircuitBreakerState,
  recordCircuitBreakerFailure,
} from '../plugins/metrics.js';

const circuitBreakers = new Map<string, CircuitBreaker>();

function getCircuitBreaker(target: string): CircuitBreaker {
  if (!circuitBreakers.has(target)) {
    const breaker = new CircuitBreaker(
      async (url: string, options: RequestInit) => {
        const response = await fetch(url, options);
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }
        return response;
      },
      {
        timeout: 10000,
        errorThresholdPercentage: 50,
        resetTimeout: 30000,
      }
    );

    breaker.on('open', () => {
      logger.warn({ target }, 'Circuit breaker opened');
      recordCircuitBreakerState(target, 'open');
    });

    breaker.on('halfOpen', () => {
      logger.info({ target }, 'Circuit breaker half-open');
      recordCircuitBreakerState(target, 'half-open');
    });

    breaker.on('close', () => {
      logger.info({ target }, 'Circuit breaker closed');
      recordCircuitBreakerState(target, 'closed');
    });

    breaker.on('failure', () => {
      recordCircuitBreakerFailure(target);
    });

    circuitBreakers.set(target, breaker);
  }

  const breaker = circuitBreakers.get(target);
  if (!breaker) {
    throw new Error(`Circuit breaker not found for target: ${target}`);
  }
  return breaker;
}

export async function proxyHandler(
  request: FastifyRequest,
  reply: FastifyReply,
  route: RouteConfig
) {
  const requestId = request.id;
  const targetUrl = route.target;
  const path = request.url.replace(route.path, '');
  const url = `${targetUrl}${path}${request.url.includes('?') ? request.url.substring(request.url.indexOf('?')) : ''}`;

  logger.info(
    {
      requestId,
      method: request.method,
      url: request.url,
      target: url,
    },
    'Proxying request'
  );

  const proxyStartTime = Date.now();

  try {
    const breaker = getCircuitBreaker(targetUrl);

    const response = (await breaker.fire(url, {
      method: request.method,
      headers: {
        ...Object.fromEntries(
          Object.entries(request.headers).filter(
            ([key]) => !['host', 'connection'].includes(key.toLowerCase())
          )
        ),
        'x-request-id': requestId,
        'x-forwarded-for': request.ip,
      },
      body:
        request.method !== 'GET' && request.method !== 'HEAD'
          ? JSON.stringify(request.body)
          : undefined,
    })) as Response;

    const data = await response.json();

    // Record metrics
    const duration = (Date.now() - proxyStartTime) / 1000;
    recordProxyRequest(targetUrl, request.method, response.status, duration);

    // Forward response headers
    Object.entries(response.headers).forEach(([key, value]) => {
      reply.header(key, value as string);
    });

    reply.status(response.status).send(data);
  } catch (error) {
    logger.error(
      {
        requestId,
        error,
        target: url,
      },
      'Proxy error'
    );

    if (error instanceof Error && error.message.includes('Circuit breaker')) {
      reply.status(503).send({
        success: false,
        error: {
          code: 'SERVICE_UNAVAILABLE',
          message: 'Service temporarily unavailable',
        },
        meta: {
          requestId,
          timestamp: new Date().toISOString(),
        },
      });
    } else {
      reply.status(500).send({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Internal server error',
        },
        meta: {
          requestId,
          timestamp: new Date().toISOString(),
        },
      });
    }
  }
}
