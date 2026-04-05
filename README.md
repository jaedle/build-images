# Build images

Generic build images for my self-hosted [Concourse](https://concourse-ci.org/).

## Release

- Build & Release of images is automated via GitHub Actions
- Hosted on [DockerHub](https://hub.docker.com/u/jaedle)

## Image Types

- `base`: Base image with common dependencies

## Runtime versions

Backed by [mise-en-place](https://mise.jdx.dev/).

- Do not pin major versions

## Entrypoint

The `base` image ships `/entrypoint.sh` which integrates with Concourse task steps.

**Features:**

- `WORKDIR` env var: cd into `./WORKDIR` before running commands; fails if the directory does not exist.
- Auto-runs `mise install` if `.mise.toml` or `mise.toml` is present in the working directory.
- Accepts arbitrary commands as args.

**Example Concourse task:**

```yaml
platform: linux
image_resource:
  type: registry-image
  source:
    repository: jaedle/build-images-base

inputs:
  - name: source-code
    
params:
  WORKDIR: source-code

run:
  path: /entrypoint.sh
  args:
    - go test ./...
    - go build .
```
