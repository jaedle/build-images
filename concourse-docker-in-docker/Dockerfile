ARG BASE_IMAGE=jaedle/build-images-base
ARG BASE_TAG=latest

FROM ${BASE_IMAGE}:${BASE_TAG}

RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    printf 'Types: deb\nURIs: https://download.docker.com/linux/debian\nSuites: %s\nComponents: stable\nArchitectures: %s\nSigned-By: /etc/apt/keyrings/docker.asc\n' \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" \
      "$(dpkg --print-architecture)" \
      > /etc/apt/sources.list.d/docker.sources && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      containerd.io \
      docker-ce \
      docker-ce-cli \
      docker-compose-plugin \
    && \
    rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
