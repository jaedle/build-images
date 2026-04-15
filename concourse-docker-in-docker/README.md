# concourse-docker-in-docker

Docker-in-Docker image for use in Concourse CI pipelines.

## Environment Variables

| Variable          | Default   | Description                                                                   |
|-------------------|-----------|-------------------------------------------------------------------------------|
| `DOCKERD_TIMEOUT` | `60`      | Seconds to wait for Docker daemon to become available                         |
| `DOCKER_OPTS`     | _(empty)_ | Additional options passed to `dockerd`; storage driver defaults to `vfs`      |
| `DOCKER_MIRROR`   | _(empty)_ | Docker Hub pull-through mirror URL (e.g. `https://docker-mirror.example.com`) |
| `NO_BINFMT_SETUP` | _(empty)_ | Skip automatic `tonistiigi/binfmt --install all` setup before user commands   |

## Cross Compilation

The image bundles `tonistiigi/binfmt` and, on startup, loads it into Docker and runs:

```bash
docker container run --privileged --rm tonistiigi/binfmt --install all
```

That makes `docker buildx` cross-compilation available by default.

Disable it with:

```bash
NO_BINFMT_SETUP=1
```

## Docker Hub Mirror

To use a pull-through cache for Docker Hub, set `DOCKER_MIRROR`:

```
DOCKER_MIRROR=https://docker-mirror.home.jaedle.de
```
