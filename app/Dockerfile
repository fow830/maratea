FROM node:22-alpine AS base

WORKDIR /app

# Install pnpm
RUN corepack enable && corepack prepare pnpm@8.15.0 --activate

FROM base AS dependencies

# Copy workspace files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY shared/package.json ./shared/
COPY app/package.json ./app/

# Install all dependencies
RUN pnpm install --frozen-lockfile

FROM base AS build

# Copy dependencies
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=dependencies /app/shared ./shared

# Copy source files
COPY tsconfig.base.json ./
COPY app ./app
COPY shared/src ./shared/src

# Build shared package (if needed)
RUN pnpm --filter @maratea/shared build || echo "Shared package build skipped"

# Build Next.js app
WORKDIR /app/app
RUN pnpm build

FROM base AS runtime

ENV NODE_ENV=production

# Copy built files
COPY --from=build /app/app/.next ./.next
COPY --from=build /app/app/public ./public
COPY --from=build /app/app/package.json ./package.json
COPY --from=build /app/app/next.config.js ./next.config.js

# Copy shared dist (if exists)
COPY --from=build /app/shared/dist ./shared/dist 2>/dev/null || true
COPY --from=build /app/shared/package.json ./shared/package.json

# Install only production dependencies
WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY shared/package.json ./shared/
COPY app/package.json ./app/
RUN pnpm install --frozen-lockfile --prod --ignore-scripts

WORKDIR /app/app

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME=0.0.0.0

CMD ["pnpm", "start"]

