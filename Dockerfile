# =============================================================================
# NEO Lite — Multi-stage Dockerfile (v1.0.0)
# =============================================================================
# Build: docker compose build
# Run:   docker compose up -d
# =============================================================================
# Stage 1: Install Hermes Agent
FROM nikolaik/python-nodejs:python3.11-nodejs20 AS hermes-builder

WORKDIR /opt/hermes

# Install Hermes Agent
RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# Pre-create required directories
RUN mkdir -p /root/.hermes/skills /root/.hermes/scripts /root/.hermes/secrets

# =============================================================================
# Stage 2: Runtime image
# =============================================================================
FROM python:3.11-slim

WORKDIR /opt/hermes

LABEL description="NEO Lite — Your AI Chief of Staff (Free Tier)"
LABEL vendor="NEO Cloud"
LABEL version="1.0.0"

# Install system deps: Node.js, curl, git (for part downloads)
RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs \
    npm \
    curl \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy Hermes from builder
COPY --from=hermes-builder /root/.local/bin/hermes /usr/local/bin/hermes
COPY --from=hermes-builder /root/.hermes /root/.hermes

# Copy NEO Lite configuration and scripts
COPY config/ /root/.hermes/
COPY scripts/ /root/.hermes/scripts/
COPY skills/ /root/.hermes/skills/

# Install NEO CLI commands
COPY scripts/neo-parts /usr/local/bin/neo-parts
RUN chmod +x /usr/local/bin/neo-parts && \
    printf '#!/bin/bash\n# NEO Lite unified CLI\ncase "${1:-}" in\n    parts) shift; exec neo-parts "$@" ;;\n    version|-v|--version) echo "NEO Lite v1.0.0" ;;\n    help|-h|--help|"") echo "Usage: neo <command> [args]\nCommands:\n  parts          Manage add-on capability parts\n  version        Show version\n  help           Show this help" ;;\n    *) echo "Unknown command: $1. Try '\''neo help'\''." ;;\nesac\n' > /usr/local/bin/neo && chmod +x /usr/local/bin/neo

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create parts directory (for add-on skill packs)
RUN mkdir -p /root/.hermes/parts

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
