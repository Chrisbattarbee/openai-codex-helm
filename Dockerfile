FROM node:24-bookworm-slim

ARG CODEX_VERSION=latest
ARG BUILD_DATE
ARG VCS_REF

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    build-essential \
    ca-certificates \
    curl \
    fzf \
    gh \
    git \
    jq \
    less \
    openssh-client \
    procps \
    python3 \
    python3-pip \
    python3-venv \
    ripgrep \
    unzip \
    zsh \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g "@openai/codex@${CODEX_VERSION}" \
    && npm cache clean --force

ENV HOME=/home/node \
    CODEX_UNSAFE_ALLOW_NO_SANDBOX=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONUNBUFFERED=1

WORKDIR /home/node

LABEL org.opencontainers.image.title="openai-codex" \
      org.opencontainers.image.description="Codex CLI runtime image with core development tools" \
      org.opencontainers.image.source="https://github.com/Chrisbattarbee/openai-codex-helm" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.version="${CODEX_VERSION}"

USER node

CMD ["bash"]
