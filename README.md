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
