FROM node:24-alpine@sha256:a34ab6d7f6f4813f4d0c5469d74685604b962fbdbf5793a7bc7b4998ecb867c8 AS tooling
RUN apk upgrade --no-cache
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

FROM node:24-alpine@sha256:a34ab6d7f6f4813f4d0c5469d74685604b962fbdbf5793a7bc7b4998ecb867c8 AS runtime
RUN apk upgrade --no-cache \
    && rm -rf /usr/local/lib/node_modules /opt/yarn* \
      /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/yarn \
      /usr/local/bin/yarnpkg /usr/local/bin/corepack
ENV NODE_ENV=production PORT=8080
WORKDIR /app
COPY --from=dependencies --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist
COPY --chown=node:node package.json LICENCE ./
USER 1000:1000
EXPOSE 8080
CMD ["node", "dist/index.js"]
