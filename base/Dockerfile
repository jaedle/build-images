FROM debian:bookworm-slim

RUN apt-get update &&  \
    apt-get install -y --no-install-recommends \
      curl \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://mise.run | sh
ENV PATH="/root/.local/bin:${PATH}"

COPY .mise.toml /root/.config/mise/config.toml

RUN mise install
