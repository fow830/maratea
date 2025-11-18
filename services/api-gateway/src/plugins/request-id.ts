import type { FastifyPluginAsync } from 'fastify';

export const requestIdPlugin: FastifyPluginAsync = async (fastify) => {
  fastify.addHook('onRequest', async (request) => {
    const requestId = request.id || crypto.randomUUID();
    request.id = requestId;
    request.headers['x-request-id'] = requestId;
  });
};
