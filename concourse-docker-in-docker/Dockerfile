ARG BASE_IMAGE=jaedle/build-images-base
ARG BASE_TAG=latest

FROM ${BASE_IMAGE}:${BASE_TAG}

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      docker.io \
      iproute2 \
    && \
    rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
