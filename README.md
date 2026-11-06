# slidev-sync-server

Synchronize [Slidev](https://sli.dev/) presentations using Server-Sent Events (SSE) or WebSocket connections.

This is an updated fork of [Smile-SA/slidev-sync-server](https://github.com/Smile-SA/slidev-sync-server), with refreshed dependencies and container distribution. Many thanks to Tony Cabaye and the upstream contributors for creating the original project.

Use it with [Morl99/slidev-addon-sync](https://github.com/Morl99/slidev-addon-sync). Follow the addon's instructions to connect your presentation to the server.

## Quick start

Run the container in SSE mode (the default):

```bash
docker run --rm --name slidev-sync-server \
  -p 8080:8080 \
  ghcr.io/morl99/slidev-sync-server:latest
```

For WebSocket mode:

```bash
docker run --rm --name slidev-sync-server \
  -p 8080:8080 -e WS=true \
  ghcr.io/morl99/slidev-sync-server:latest
```

The server listens on port 8080. Configure the addon to use your server's address.
Choose the matching transport in the addon. The container uses Node.js on Alpine
and runs as a non-root user. Published images currently target **linux/amd64**.

## Kubernetes / Helm

A [simple Helm chart](charts/slidev-sync-server/README.md) is included for Kubernetes:

```bash
helm upgrade --install slidev-sync oci://ghcr.io/morl99/charts/slidev-sync-server \
  --namespace slidev-sync --create-namespace
```

See the chart guide for configuration,
WebSocket mode and deployment considerations.

## Configuration

Pass environment variables using Docker's `-e NAME=value` option.

| Variable | Default | Purpose |
| --- | --- | --- |
| `PORT` | `8080` | Port inside the container. Adjust the container port in `-p` if you change it. |
| `WS` | Unset (SSE) | Set to `true` to enable WebSocket mode. Any non-empty value enables it, including `false`; leave it unset for SSE. |
| `DEBUG` | `error` | Log level: `error`, `warn` or `info`. |
| `CORS_ORIGIN` | `*` | Allowed origin for SSE responses, for example `https://slides.example.com`. |

Example with an explicit SSE origin and more detailed logs:

```bash
docker run --rm -p 8080:8080 \
  -e CORS_ORIGIN=https://slides.example.com \
  -e DEBUG=info \
  ghcr.io/morl99/slidev-sync-server:latest
```

## Operating the server

Synchronization state is kept in memory and is lost when the server restarts.
No persistent volume is required. Separate server instances do not share state.

Provide TLS and access control through your deployment, such as a reverse proxy
or private network. For SSE, configure the proxy to allow long-lived responses
without buffering; for WebSocket mode, enable WebSocket forwarding.

`latest` tracks published images from `main`. For reproducible deployments, pin
an image digest. Images include a Cosign signature and a signed CycloneDX SBOM;
verification details are in [CONTRIBUTING.md](CONTRIBUTING.md#image-verification).

## Help and contributions

Questions, bug reports and suggestions are welcome in
[Issues](https://github.com/Morl99/slidev-sync-server/issues).
Want to contribute or run from source? See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENCE). Original authorship and license notices are retained.
