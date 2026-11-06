# slidev-sync-server

WebSocket server for [Slidev](https://sli.dev/).

You can use this server easily with the [slidev-addon-sync](https://github.com/Smile-SA/slidev-addon-sync) addon.

## Installation

Get source code or git clone this repo.

Requires Node.js 24 and pnpm 12.18.0.

Install dependencies:
```bash
pnpm install --frozen-lockfile
```

Then build the files:
```bash
pnpm build
```

Finally start the server:
```bash
pnpm start
```

## Configuration

You can configure the project using environment variables.

Example:
```bash
DEBUG=info pnpm start
```

Available environment variables:

| Variable | Type | Default value | Description |
|---|---|---|---|
| PORT | `number` | `8080` | Change running port |
| DEBUG | `'error' \| 'warn' \| 'info'` | `'error'` | Debug level |
| WS | `boolean` | `false` | use WebSocket if `true`, else use HTTP Server Sent Events |
| CORS_ORIGIN | `string` | `'*'` | Access-Control-Allow-Origin header for HTTP SSE |

## Tests

After building, run `pnpm test` to smoke-test SSE and WebSocket connections and state updates.
GitHub Actions runs installation, build and smoke tests on pushes and pull requests.

## Container image

The image uses Node.js 24 on Alpine, runs as the `node` user and contains only
compiled JavaScript and production dependencies.

```bash
docker run --rm -p 8080:8080 ghcr.io/morl99/slidev-sync-server:latest
# WebSocket mode:
docker run --rm -p 8080:8080 -e WS=true ghcr.io/morl99/slidev-sync-server:latest
```

Existing environment variables also apply to the container. No persistent volume is required;
synchronization state is held in memory.

Build and verify locally:

```bash
docker build -t slidev-sync-server:local .
sh test/container-smoke.sh slidev-sync-server:local
```

The container workflow tests pull requests without publishing. Pushes to `main`
publish `latest` and `sha-<commit>` tags to GHCR after the image smoke tests pass.
Version tags (`v*`) publish the corresponding version tag. The workflow can also
be started manually on `main`. Publication uses the repository `GITHUB_TOKEN`.
The first GHCR package may need its visibility changed to public in package settings.
