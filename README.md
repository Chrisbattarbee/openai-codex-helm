# OpenAI Codex Helm Chart

[![Helm 3](https://img.shields.io/badge/Helm-3.0+-0f1689?logo=helm&logoColor=white)](https://helm.sh/)
[![Kubernetes 1.19+](https://img.shields.io/badge/Kubernetes-1.19+-326ce5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A Helm chart for running [Codex CLI](https://github.com/openai/codex) in Kubernetes as a long-lived pod with a persistent HOME directory.

---

## Quick Start

```bash
helm repo add openai-codex https://chrisbattarbee.github.io/openai-codex-helm
helm repo update
helm install codex openai-codex/openai-codex
```

Wait for the pod and open a shell:

```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=codex --timeout=120s
kubectl exec -it deploy/codex-openai-codex -c codex -- sh
codex
```

---

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Docker (if you want to build/publish your own image)

> The chart does not install Codex at startup. It expects `image.repository:image.tag` to be ready-to-run (defaults to `ghcr.io/chrisbattarbee/openai-codex:0.98.0`).

---

## Persistence Model

By default, the chart mounts a PersistentVolumeClaim at `/home/node`. This means:

- `~/.codex` (auth/config/logs) persists across pod restarts
- interactive login state survives restarts
- any additional files in `/home/node` persist

Disable persistence if needed:

```bash
helm install codex openai-codex/openai-codex \
  --set image.repository=<your-codex-image> \
  --set image.tag=<your-tag> \
  --set persistence.enabled=false
```

---

## Authentication Options

### 1) Use an existing secret

Create a secret with your provider keys:

```bash
kubectl create secret generic codex-credentials \
  --from-literal=OPENAI_API_KEY=sk-xxx
```

Install with:

```bash
helm install codex openai-codex/openai-codex \
  --set image.repository=<your-codex-image> \
  --set image.tag=<your-tag> \
  --set credentials.existingSecret=codex-credentials
```

### 2) Let the chart create a secret

```bash
helm install codex openai-codex/openai-codex \
  --set image.repository=<your-codex-image> \
  --set image.tag=<your-tag> \
  --set credentials.openaiApiKey=sk-xxx
```

### 3) Login interactively inside the pod

`codex` login artifacts are written under `/home/node/.codex` and persist because HOME is PVC-backed by default.

---

## Image Publishing

This repository includes a multi-arch image workflow at [`.github/workflows/build-image.yaml`](.github/workflows/build-image.yaml).

- Push to `main` publishes:
  - `ghcr.io/chrisbattarbee/openai-codex:latest`
  - `ghcr.io/chrisbattarbee/openai-codex:sha-<shortsha>`
- Push a tag named `codex-X.Y.Z` publishes:
  - `ghcr.io/chrisbattarbee/openai-codex:X.Y.Z`
  - `ghcr.io/chrisbattarbee/openai-codex:latest`
- Images are built for both `linux/amd64` and `linux/arm64`.

Codex version baked into the image is controlled by the workflow:

- `main` builds install `@openai/codex@latest`
- `codex-X.Y.Z` tag builds install `@openai/codex@X.Y.Z`

For reproducibility, Helm defaults should point to explicit version tags rather than `latest`.

---

## Key Values

| Parameter                   | Description                                         | Default        |
| --------------------------- | --------------------------------------------------- | -------------- |
| `image.repository`          | Prebuilt image containing `codex`                   | `ghcr.io/chrisbattarbee/openai-codex` |
| `image.tag`                 | Image tag                                           | `0.98.0`       |
| `command`                   | Container command (idle by default)                 | `sh -lc sleep infinity` |
| `credentials.existingSecret`| Existing secret for env vars                        | `""`           |
| `credentials.openaiApiKey`  | API key for chart-managed secret                    | `""`           |
| `credentials.secretData`    | Extra chart-managed secret key/value pairs          | `{}`           |
| `persistence.enabled`       | Persist `/home/node`                                | `true`         |
| `persistence.size`          | PVC size                                            | `5Gi`          |
| `persistence.existingClaim` | Use existing PVC instead of creating one            | `""`           |

See [`charts/openai-codex/values.yaml`](charts/openai-codex/values.yaml) for the full configuration.

---

## Uninstall

```bash
helm uninstall codex
```

PVC is not deleted automatically. Delete it manually if you want to remove persisted HOME data:

```bash
kubectl delete pvc codex-openai-codex
```
