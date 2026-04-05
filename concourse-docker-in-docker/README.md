# concourse-docker-in-docker

Docker-in-Docker image for use in Concourse CI pipelines.

## Environment Variables

| Variable          | Default   | Description                                                                   |
|-------------------|-----------|-------------------------------------------------------------------------------|
| `DOCKERD_TIMEOUT` | `60`      | Seconds to wait for Docker daemon to become available                         |
| `DOCKER_OPTS`     | _(empty)_ | Additional options passed to `dockerd`                                        |
| `DOCKER_MIRROR`   | _(empty)_ | Docker Hub pull-through mirror URL (e.g. `https://docker-mirror.example.com`) |

## Docker Hub Mirror

To use a pull-through cache for Docker Hub, set `DOCKER_MIRROR`:

```
DOCKER_MIRROR=https://docker-mirror.home.jaedle.de
```
