# Build images

Generic build images for my self-hosted [Concourse](https://concourse-ci.org/).

## Release

- Build & Release of images is automated via GitHub Actions
- Hosted on [DockerHub](https://hub.docker.com/u/jaedle)

## Image Types

- `base`: Base image with common dependencies
- `backup`: Image based on `base` for backup workloads
- `concourse-docker-in-docker`: Concourse task image with Docker-in-Docker, built on top of `base`

## Runtime versions

Backed by [mise-en-place](https://mise.jdx.dev/).

- Do not pin major versions

## Entrypoint

The `base` image ships `/entrypoint.sh` which integrates with Concourse task steps.

**Features:**

- `WORKDIR` env var: cd into `./WORKDIR` before running commands; fails if the directory does not exist.
- Auto-runs `mise install` if `.mise.toml` or `mise.toml` is present in the working directory.
- Accepts arbitrary commands as args.

The `concourse-docker-in-docker` image keeps the same entrypoint behavior and starts `dockerd` before running task commands. Run Concourse tasks with `privileged: true`.

Before user commands run, it also loads a bundled `tonistiigi/binfmt` image and executes `docker container run --privileged --rm tonistiigi/binfmt --install all` so `docker buildx` cross-compilation works by default.

Set `NO_BINFMT_SETUP=1` to skip that automatic setup.

`dockerd` defaults to `--storage-driver vfs` unless `DOCKER_OPTS` already sets a storage driver.

**Example Concourse task:**

```yaml
platform: linux
image_resource:
  type: registry-image
  source:
    repository: `jaedle/build-images-base`

inputs:
  - name: source-code
    
params:
  WORKDIR: source-code
  # NO_BINFMT_SETUP: 1

run:
  path: /entrypoint.sh
  args:
    - go test ./...
    - go build .
```

**Example Docker-in-Docker task:**

```yaml
platform: linux
image_resource:
  type: registry-image
  source:
    repository: jaedle/build-images-concourse-docker-in-docker

privileged: true

inputs:
  - name: source-code

params:
  WORKDIR: source-code

run:
  path: /docker-entrypoint.sh
  args:
    - docker version
    - docker container run --rm -i hello-world
```
