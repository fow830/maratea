import { isAppError, logger } from '@maratea/shared';
import type { FastifyError, FastifyReply, FastifyRequest } from 'fastify';

export async function errorHandler(
  error: FastifyError,
  request: FastifyRequest,
  reply: FastifyReply
) {
  const requestId = request.id;

  logger.error(
    {
      requestId,
      error: {
        message: error.message,
        stack: error.stack,
        code: error.code,
      },
      url: request.url,
      method: request.method,
    },
    'Request error'
  );

  if (isAppError(error)) {
    reply.status(error.statusCode).send({
      success: false,
      error: {
        code: error.code,
        message: error.message,
      },
      meta: {
        requestId,
        timestamp: new Date().toISOString(),
      },
    });
    return;
  }

  // Default error response
  const statusCode = error.statusCode ?? 500;
  reply.status(statusCode).send({
    success: false,
    error: {
      code: 'INTERNAL_ERROR',
      message: process.env.NODE_ENV === 'production' ? 'Internal server error' : error.message,
    },
    meta: {
      requestId,
      timestamp: new Date().toISOString(),
    },
  });
}
