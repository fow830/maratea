FROM node:22-alpine AS base

WORKDIR /app

# Install pnpm (доступен глобально, чтобы не требовать сеть в рантайме)
RUN corepack enable \
  && corepack prepare pnpm@8.15.0 --activate \
  && npm install -g pnpm@8.15.0 --force

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
# Create public directory if it doesn't exist (Next.js requires it)
RUN mkdir -p ./public || true
RUN pnpm build

FROM base AS runtime

ENV NODE_ENV=production

# Copy built files
COPY --from=build /app/app/.next ./.next
COPY --from=build /app/app/package.json ./package.json
COPY --from=build /app/app/next.config.js ./next.config.js

# Copy public directory (will be empty if not created)
RUN mkdir -p ./public
COPY --from=build /app/app/public ./public

# Copy shared package.json (shared/dist is not needed at runtime for Next.js)
RUN mkdir -p ./shared
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

