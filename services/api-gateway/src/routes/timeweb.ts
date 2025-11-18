import type { FastifyPluginAsync } from 'fastify';
import { TimewebClient } from '../services/timeweb.js';

export const timewebRoutes: FastifyPluginAsync = async (fastify) => {
  const client = new TimewebClient();

  fastify.get('/domains', async () => {
    const domains = await client.listDomains();

    return {
      source: 'timeweb',
      count: domains.length,
      domains,
    };
  });

  fastify.get('/balance', async () => {
    const finances = await client.getAccountFinances();

    return {
      source: 'timeweb',
      finances,
    };
  });
};
