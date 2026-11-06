# Contributing

Thanks for your interest in improving slidev-sync-server! Issues, ideas,
documentation fixes and pull requests (merge requests) are all welcome.
Small contributions are just as appreciated as larger ones.

This repository is an updated fork of
[Smile-SA/slidev-sync-server](https://github.com/Smile-SA/slidev-sync-server).
Please respect the original authorship and retain the existing license notices.

## Reporting issues and suggesting changes

Check [existing issues](https://github.com/Morl99/slidev-sync-server/issues)
before opening a new one. For a bug report, please include:

- What you expected and what happened.
- Steps to reproduce, and whether you use SSE or WebSocket mode.
- Your Node.js version or container image tag/digest, addon version and relevant logs.

Please remove credentials, private presentation content and other sensitive
information from examples and logs. For a larger change, opening an issue first
can help agree on the approach.

## Local setup

Use the Node.js version recorded in `.node-version` and the pnpm version
pinned in the `packageManager` field of `package.json`.

```bash
git clone https://github.com/Morl99/slidev-sync-server.git
cd slidev-sync-server
pnpm install --frozen-lockfile
pnpm build
pnpm test
```

If you plan to submit a pull request without write access, fork the repository
first and clone your own fork.

## Developing and running

TypeScript source lives in `src/`; `pnpm build` writes JavaScript to `dist/`.
Run the built server with:

```bash
pnpm start
# Or run WebSocket mode:
WS=true pnpm start
```

Rebuild after changing source files. For incremental development, keep the
compiler running in one terminal:

```bash
pnpm exec tsc --watch
```

Start the server in another terminal and restart it after changes. There is no
dedicated hot-reload script. See the [README](README.md#configuration) for runtime
configuration. Example clients are available in `examples/sse.html` and
`examples/ws.html`.

## Tests and container builds

After building, `pnpm test` runs network smoke tests against the compiled server,
covering SSE connections and updates, plus WebSocket initial state and patch
broadcasts. Keep tests focused on observable behavior.

To build and smoke-test the runtime image, install Docker and run:

```bash
docker build -t slidev-sync-server:local .
sh test/container-smoke.sh slidev-sync-server:local
```

The multi-stage build runs the server tests before assembling the runtime image.
Only compiled code and production dependencies are copied into the non-root
Alpine runtime. npm and Yarn are removed from the runtime image.

## Submitting a pull request

Create a branch, keep the change focused and explain the problem it solves.
Include reproduction steps or test results when relevant, and update the docs
when behavior changes. Please run `pnpm build` and `pnpm test` before submitting.
Documentation-only changes do not need new tests.

The required `build` and `verify` checks must pass before merging. The container
workflow builds the image, smoke-tests both transports, scans it with Trivy and
generates a CycloneDX SBOM. HIGH or CRITICAL vulnerabilities block publication,
including findings without an available fix. Pull requests do not publish images.

## Dependencies and releases

Dependabot proposes npm and GitHub Actions updates weekly and Docker base-image
updates daily. The configured Node.js major version is retained. Verified Dependabot Patch/Minor updates
can auto-merge once required checks pass; Major updates and unknown classifications
remain manual. Digest updates are eligible when classified as Patch.

When changing dependencies manually, update and commit both `package.json` and
`pnpm-lock.yaml`. Use the pinned pnpm version so its package-manager lockfile
document remains consistent with frozen CI installations.

The container workflow runs on pushes to `main`, version tags (`v*`), manual
dispatches and nightly at **02:23 UTC**. Rebuilds use `apk upgrade --no-cache`
without cached build layers. A separate publishing job receives the exact tested
image, checks the archive checksum, and uses `GITHUB_TOKEN` for GHCR and OIDC
for keyless Cosign signing. Actions and base images are pinned by SHA/digest.

Publication compares the canonical runtime package inventory and a hash of source
and container configuration against the previous verified signed SBOM. Timestamps
do not trigger publication. Unchanged contents are skipped, including manual and
version-tag runs.

Changed images receive a unique commit/run tag. The `latest` alias advances on
`main` only after image and SBOM signing succeed; version-tag runs add their
version alias only when a new image is published. An existing package with a
missing or invalid baseline attestation blocks publication. The first GHCR
package may need its visibility changed to public in package settings.

## Image verification

Use Cosign and replace `DIGEST` with the exact image digest you intend to deploy:

```bash
cosign verify \
  --certificate-identity 'https://github.com/Morl99/slidev-sync-server/.github/workflows/container.yml@refs/heads/main' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/morl99/slidev-sync-server@sha256:DIGEST

cosign verify-attestation --type cyclonedx \
  --certificate-identity 'https://github.com/Morl99/slidev-sync-server/.github/workflows/container.yml@refs/heads/main' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/morl99/slidev-sync-server@sha256:DIGEST
```

For an image published by a version-tag run, use that run's exact
`@refs/tags/v...` workflow identity instead of `@refs/heads/main`.
