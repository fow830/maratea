import type { FastifyPluginAsync, FastifyRequest, FastifyReply } from 'fastify';
import { Registry, Counter, Histogram, Gauge } from 'prom-client';

// Создаем отдельный registry для метрик приложения
const register = new Registry();

// Метрики HTTP запросов
const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10],
  registers: [register],
});

const httpRequestTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

const httpRequestErrors = new Counter({
  name: 'http_request_errors_total',
  help: 'Total number of HTTP request errors',
  labelNames: ['method', 'route', 'error_type'],
  registers: [register],
});

// Метрики для proxy запросов
const proxyRequestDuration = new Histogram({
  name: 'proxy_request_duration_seconds',
  help: 'Duration of proxy requests in seconds',
  labelNames: ['target', 'method', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10],
  registers: [register],
});

const proxyRequestTotal = new Counter({
  name: 'proxy_requests_total',
  help: 'Total number of proxy requests',
  labelNames: ['target', 'method', 'status_code'],
  registers: [register],
});

// Метрики для circuit breaker
const circuitBreakerState = new Gauge({
  name: 'circuit_breaker_state',
  help: 'Circuit breaker state (0=closed, 1=open, 2=half-open)',
  labelNames: ['target'],
  registers: [register],
});

const circuitBreakerFailures = new Counter({
  name: 'circuit_breaker_failures_total',
  help: 'Total number of circuit breaker failures',
  labelNames: ['target'],
  registers: [register],
});

// Метрики для rate limiting
const rateLimitHits = new Counter({
  name: 'rate_limit_hits_total',
  help: 'Total number of rate limit hits',
  labelNames: ['route'],
  registers: [register],
});

// Метрики процесса
const processMemoryUsage = new Gauge({
  name: 'process_memory_usage_bytes',
  help: 'Process memory usage in bytes',
  labelNames: ['type'],
  registers: [register],
});


// Обновляем метрики процесса каждые 5 секунд
if (typeof setInterval !== 'undefined') {
  setInterval(() => {
    const usage = process.memoryUsage();
    processMemoryUsage.set({ type: 'heapUsed' }, usage.heapUsed);
    processMemoryUsage.set({ type: 'heapTotal' }, usage.heapTotal);
    processMemoryUsage.set({ type: 'rss' }, usage.rss);
    processMemoryUsage.set({ type: 'external' }, usage.external);
  }, 5000);
}

export const metricsPlugin: FastifyPluginAsync = async (fastify) => {
  // Endpoint для экспорта метрик Prometheus
  fastify.get('/metrics', async (_request: FastifyRequest, reply: FastifyReply) => {
    reply.type('text/plain');
    return register.metrics();
  });

  // Hook для сбора метрик HTTP запросов
  fastify.addHook('onRequest', async (request) => {
    request.metricsStartTime = Date.now();
  });

  fastify.addHook('onResponse', async (request, reply) => {
    const duration = (Date.now() - (request.metricsStartTime || Date.now())) / 1000;
    const method = request.method;
    const route = request.routerPath || request.url.split('?')[0] || 'unknown';
    const statusCode = reply.statusCode.toString();

    httpRequestDuration.observe({ method, route, status_code: statusCode }, duration);
    httpRequestTotal.inc({ method, route, status_code: statusCode });

    if (reply.statusCode >= 400) {
      const errorType = reply.statusCode >= 500 ? 'server_error' : 'client_error';
      httpRequestErrors.inc({ method, route, error_type: errorType });
    }
  });

  fastify.addHook('onError', async (request, _reply, error) => {
    const method = request.method;
    const route = request.routerPath || request.url.split('?')[0] || 'unknown';
    const errorType = error.name || 'unknown_error';

    httpRequestErrors.inc({ method, route, error_type: errorType });
  });
};

// Экспортируем функции для использования в других местах
export function recordProxyRequest(
  target: string,
  method: string,
  statusCode: number,
  duration: number
) {
  proxyRequestDuration.observe({ target, method, status_code: statusCode.toString() }, duration);
  proxyRequestTotal.inc({ target, method, status_code: statusCode.toString() });
}

export function recordCircuitBreakerState(target: string, state: 'closed' | 'open' | 'half-open') {
  const stateValue = state === 'closed' ? 0 : state === 'open' ? 1 : 2;
  circuitBreakerState.set({ target }, stateValue);
}

export function recordCircuitBreakerFailure(target: string) {
  circuitBreakerFailures.inc({ target });
}

export function recordRateLimitHit(route: string) {
  rateLimitHits.inc({ route });
}

