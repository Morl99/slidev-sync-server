# Slidev sync server Helm chart

Deploy the server into an existing Kubernetes cluster:

```bash
helm upgrade --install slidev-sync oci://ghcr.io/morl99/charts/slidev-sync-server \
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

An optional Ingress supports IngressClass, hosts, paths and TLS secrets. An Ingress
controller must already be installed. Supply controller-specific annotations to
disable SSE buffering and configure suitable connection timeouts/WebSocket
forwarding. Authentication and certificate issuance remain deployment concerns. The default node selector matches the architecture
of the currently published images.

Uninstall with:

```bash
helm uninstall slidev-sync --namespace slidev-sync
```

The OCI chart is published to GHCR after chart checks pass on the default branch.
Use `--version CHART_VERSION` to select a release. Published versions are never
overwritten; identical content skips the upload, while changed content requires
a chart version bump. The workflow signs each chart digest using keyless Cosign.
The GHCR chart package must be public for anonymous installation.

To install from a checkout instead, use `./charts/slidev-sync-server` as the chart
argument. This is also useful before the first chart publication.

## Labels, annotations and Ingress

Global `commonLabels` are combined with resource-specific `deployment.labels`,
`pod.labels`, `serviceMetadata.labels` and `ingress.labels`. The matching
`annotations` maps are supported per resource. Resource-specific labels override
common labels; chart-owned selector/identity labels take precedence over both.

Example override values (adapt the IngressClass and annotations to your controller):

```yaml
commonLabels:
  team: presentations
deployment:
  annotations:
    example.com/owner: platform
pod:
  annotations:
    example.com/purpose: slide-sync
serviceMetadata:
  labels:
    exposure: internal
ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/proxy-buffering: "off"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
  hosts:
    - host: slides.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: slides-tls
      hosts:
        - slides.example.com
```

The TLS secret must exist in the release namespace, or be provisioned by your
certificate controller. Use the root path unless your proxy explicitly rewrites
a prefix: the server has no configurable base path.

## Pod and container security contexts

`podSecurityContext` and `securityContext` pass Kubernetes security-context
fields through to the Pod and server container respectively. Defaults retain
non-root execution, RuntimeDefault seccomp, a read-only root filesystem, dropped
capabilities and disabled privilege escalation.

No UID, GID or fsGroup is set by the chart. OpenShift can assign IDs from the
namespace range through its SCC admission policy. On Kubernetes without UID
injection, use the image's numeric non-root user. Upgrade the server image to
a build with that numeric user declaration as well as upgrading the chart;
an older image with a named user may fail Kubernetes' non-root verification.

If your cluster requires explicit IDs, configure values appropriate to its policy:

```yaml
podSecurityContext:
  runAsUser: 1000853000
  runAsGroup: 1000853000
securityContext:
  runAsNonRoot: true
```

These IDs are examples, not universal OpenShift defaults. Keep the secure defaults
unless your cluster policy requires a change. Helm merges partial object overrides
with the defaults; set an individual inherited key to `null` if it must be removed.
