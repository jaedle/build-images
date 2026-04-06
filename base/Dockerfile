FROM debian:bookworm-slim

RUN apt-get update &&  \
    apt-get install -y --no-install-recommends \
      curl \
      ca-certificates \
      gnupg \
      iproute2 \
      jq \
    && \
    rm -rf /var/lib/apt/lists/*

RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://mise.jdx.dev/gpg-key.pub | gpg --dearmor -o /etc/apt/keyrings/mise.gpg && \
    chmod a+r /etc/apt/keyrings/mise.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/mise.gpg] https://mise.jdx.dev/deb stable main" > /etc/apt/sources.list.d/mise.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends mise && \
    rm -rf /var/lib/apt/lists/*

COPY .mise.toml /root/.config/mise/config.toml
RUN mise install

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

## Disable progress bars + colors

ENV TERM=dumb
ENV CI=true
ENV NPM_CONFIG_PROGRESS=false
ENV NO_COLOR=1

ENTRYPOINT ["/entrypoint.sh"]
