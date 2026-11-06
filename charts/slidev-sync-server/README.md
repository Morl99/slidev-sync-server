# Slidev sync server Helm chart

Deploy the server into an existing Kubernetes cluster from a local checkout:

```bash
helm upgrade --install slidev-sync ./charts/slidev-sync-server \
  --namespace slidev-sync --create-namespace
```

For WebSocket mode, add `--set config.websocket=true`.
The default is SSE. For reproducible deployments, pass
`--set image.digest=sha256:YOUR_IMAGE_DIGEST`; the digest takes precedence over
`image.tag`. For private GHCR packages, configure `imagePullSecrets` with an
existing pull secret in the release namespace.

Access the ClusterIP Service locally:

```bash
kubectl -n slidev-sync port-forward service/slidev-sync-slidev-sync-server 8080:80
```

Configure the [addon](https://github.com/Morl99/slidev-addon-sync) to use the
server address and the matching transport.

| Value | Purpose |
| --- | --- |
| `image.repository`, `image.tag`, `image.digest` | Container image reference; prefer a digest. |
| `image.pullPolicy`, `imagePullSecrets` | Image pulling and registry authentication. |
| `service.port` | ClusterIP Service port. |
| `config.websocket` | Enable WebSocket instead of SSE. |
| `config.debug` | Logging: error, warn or info. |
| `config.corsOrigin` | Allowed origin for SSE responses. |
| `resources` | Container resource requests and limits. |
| `nodeSelector`, `tolerations`, `affinity` | Pod placement. |

See [values.yaml](values.yaml) for defaults.

The chart deliberately uses one replica and the Recreate update strategy:
instances do not share state. Upgrades briefly interrupt service and discard
in-memory state. There is no persistent storage or autoscaling.

Pods use a non-root user, a read-only root filesystem, dropped Linux capabilities
and the runtime's default seccomp profile. They do not mount a service-account
token. TCP probes work with both transports and check whether the listening
socket is available, rather than application-level synchronization.

The chart creates no Ingress. Provide TLS, authentication and external routing
in your deployment; disable proxy buffering for SSE and enable WebSocket
forwarding when appropriate. The default node selector matches the architecture
of the currently published images.

Uninstall with:

```bash
helm uninstall slidev-sync --namespace slidev-sync
```
