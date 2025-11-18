FROM node:22-alpine AS base

WORKDIR /app

# Install pnpm
RUN corepack enable && corepack prepare pnpm@8.15.0 --activate

FROM base AS dependencies

# Copy workspace files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY shared/package.json ./shared/
COPY landing/package.json ./landing/

# Install all dependencies
RUN pnpm install --frozen-lockfile

FROM base AS build

# Copy dependencies
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=dependencies /app/shared ./shared

# Copy source files
COPY tsconfig.base.json ./
COPY landing ./landing
COPY shared/src ./shared/src

# Build Next.js landing (static export)
WORKDIR /app/landing
RUN pnpm build

FROM nginx:alpine AS runtime

# Copy static files from Next.js export
COPY --from=build /app/landing/out /usr/share/nginx/html

# Copy nginx configuration
COPY landing/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

