ARG BASE_IMAGE=jaedle/build-images-base
ARG BASE_TAG=latest

FROM ${BASE_IMAGE}:${BASE_TAG}

RUN apt-get update &&  \
    apt-get install -y --no-install-recommends \
      expect \
      ssh \
    && \
    rm -rf /var/lib/apt/lists/*

RUN mise install aws@2 age@latest && mise use -g aws@2 age@latest