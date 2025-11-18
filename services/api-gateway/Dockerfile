FROM node:22-alpine AS base

WORKDIR /app

# Install pnpm
RUN corepack enable && corepack prepare pnpm@8.15.0 --activate

FROM base AS dependencies

# Copy all package files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY shared/package.json ./shared/
COPY services/api-gateway/package.json ./services/api-gateway/

# Install all dependencies
RUN pnpm install --frozen-lockfile

FROM base AS build

# Copy node_modules and ALL source files
COPY --from=dependencies /app/node_modules ./node_modules
COPY shared ./shared
COPY services/api-gateway ./services/api-gateway
COPY tsconfig.base.json ./

# Build shared and api-gateway
RUN pnpm --filter @maratea/shared build
RUN pnpm --filter @maratea/api-gateway build

FROM base AS runtime

ENV NODE_ENV=production

# Install pnpm
RUN corepack enable && corepack prepare pnpm@8.15.0 --activate

# Copy package files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY shared/package.json ./shared/
COPY services/api-gateway/package.json ./services/api-gateway/

# Install production dependencies (pnpm will handle workspace correctly)
RUN pnpm install --frozen-lockfile --prod --ignore-scripts || \
    (sed -i.bak '/"prepare"/d' package.json && \
     pnpm install --frozen-lockfile --prod --ignore-scripts && \
     mv package.json.bak package.json 2>/dev/null || true)

# Copy built files
COPY --from=build /app/services/api-gateway/dist ./services/api-gateway/dist
COPY --from=build /app/shared/dist ./shared/dist

EXPOSE 8080

WORKDIR /app/services/api-gateway

CMD ["node", "dist/index.js"]
