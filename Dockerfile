# syntax=docker/dockerfile:1
FROM node:24-alpine AS tooling
WORKDIR /app
RUN npm install --global pnpm@12.18.0
COPY package.json pnpm-lock.yaml ./

FROM tooling AS build
RUN pnpm install --frozen-lockfile --ignore-scripts
COPY tsconfig.json ./
COPY src ./src
COPY test ./test
RUN pnpm build && pnpm test

FROM tooling AS dependencies
RUN pnpm install --frozen-lockfile --prod --ignore-scripts

FROM node:24-alpine AS runtime
ENV NODE_ENV=production PORT=8080
WORKDIR /app
COPY --from=dependencies --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist
COPY --chown=node:node package.json LICENCE ./
USER node
EXPOSE 8080
CMD ["node", "dist/index.js"]
