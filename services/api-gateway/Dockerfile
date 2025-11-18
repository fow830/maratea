FROM node:22-alpine AS base

WORKDIR /app

# Install pnpm
RUN corepack enable && corepack prepare pnpm@8.15.0 --activate

FROM base AS dependencies

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY shared ./shared
COPY services/api-gateway/package.json ./services/api-gateway/

RUN pnpm install --frozen-lockfile

FROM base AS build

COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=dependencies /app/shared ./shared
COPY services/api-gateway ./services/api-gateway
COPY tsconfig.base.json ./

RUN pnpm --filter @maratea/shared build
RUN pnpm --filter @maratea/api-gateway build

FROM base AS runtime

ENV NODE_ENV=production

COPY --from=build /app/services/api-gateway/dist ./dist
COPY --from=build /app/shared/dist ./shared/dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/services/api-gateway/package.json ./

EXPOSE 8080

CMD ["node", "dist/index.js"]

