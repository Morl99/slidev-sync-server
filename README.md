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

The container workflow builds and tests pull requests with read-only permissions.
A separate job publishes the exact tested image to GHCR using GITHUB_TOKEN and
keyless Cosign signatures plus a signed CycloneDX SBOM. No repository code is
executed in the publishing job. HIGH/CRITICAL OS or library vulnerabilities block
publication, including findings without an available fix.

A nightly rebuild runs at 02:23 UTC and refreshes Alpine packages with
`apk upgrade --no-cache`, without cached build layers. Dependabot proposes npm
and GitHub Actions updates weekly and Docker digest updates daily; Node stays
on major 24. Dependabot Patch/Minor updates (including digest updates classified as Patch)\nuse auto-merge after required checks pass. Major and unknown classifications\nremain manual; the metadata action verifies the Dependabot PR. No PR code is\nchecked out in the privileged auto-merge workflow.

Publication compares a canonical package inventory (including package hashes)
and a source/container configuration hash with the previous signed SBOM. No new
image is published when both are unchanged, including on manual or tag runs.
Image timestamps and SBOM timestamps do not affect the comparison. `latest`
advances only after signing succeeds; each release also has a unique commit/run
tag. A v* trigger adds its version tag only when a new image is published.
First publication needs no baseline; an existing image with an invalid or missing
SBOM signature blocks comparison. The first GHCR package may need its visibility
changed to public in package settings. All images currently target linux/amd64.
