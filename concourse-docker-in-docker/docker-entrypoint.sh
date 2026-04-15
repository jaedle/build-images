#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset

DOCKERD_TIMEOUT="${DOCKERD_TIMEOUT:-60}"
DOCKER_OPTS="${DOCKER_OPTS:-}"
DOCKER_MIRROR="${DOCKER_MIRROR:-}"

DOCKERD_PID_FILE="/tmp/docker.pid"
DOCKERD_LOG_FILE="/tmp/docker.log"
BASE_ENTRYPOINT="/entrypoint.sh"
BINFMT_IMAGE_ARCHIVE="/opt/binfmt/binfmt.tar"

setup_buildx() {
  echo >&2 "Creating docker-container buildx builder..."
  docker buildx create --name multi --driver docker-container --use
}

setup_binfmt() {
  if [[ -n "${NO_BINFMT_SETUP:-}" ]]; then
    echo >&2 "Skipping binfmt setup because NO_BINFMT_SETUP is set."
    return 0
  fi

  if [[ ! -f "${BINFMT_IMAGE_ARCHIVE}" ]]; then
    echo >&2 "binfmt image archive not found: ${BINFMT_IMAGE_ARCHIVE}"
    exit 1
  fi

  echo >&2 "Loading bundled binfmt image..."
  docker image load --input "${BINFMT_IMAGE_ARCHIVE}" >/dev/null

  echo >&2 "Installing binfmt handlers..."
  docker container run --privileged --rm tonistiigi/binfmt --install all
}

sanitize_cgroups() {
  local cgroup="/sys/fs/cgroup"
  local cgroup_type

  cgroup_type="$(stat -fc %T "${cgroup}")"

  if [[ "${cgroup_type}" == "cgroup2fs" ]]; then
    export container=docker
    return 0
  fi

  mkdir -p "${cgroup}"
  if ! mountpoint -q "${cgroup}"; then
    if ! mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup "${cgroup}"; then
      echo >&2 "Could not make a tmpfs mount. Did you use --privileged?"
      exit 1
    fi
  fi
  mount -o remount,rw "${cgroup}"

  export container=docker

  if [[ -d /sys/kernel/security ]] && ! mountpoint -q /sys/kernel/security; then
    if ! mount -t securityfs none /sys/kernel/security; then
      echo >&2 "Could not mount /sys/kernel/security."
      echo >&2 "AppArmor detection and --privileged mode might break."
    fi
  fi

  sed -e 1d /proc/cgroups | while read -r sys hierarchy num enabled; do
    if [[ "${enabled}" != "1" ]]; then
      continue
    fi

    local grouping
    grouping="$(cut -d: -f2 /proc/self/cgroup | grep "\\<${sys}\\>" || true)"
    if [[ -z "${grouping}" ]]; then
      grouping="${sys}"
    fi

    local mountpoint_path="${cgroup}/${grouping}"

    mkdir -p "${mountpoint_path}"

    if mountpoint -q "${mountpoint_path}"; then
      umount "${mountpoint_path}"
    fi

    mount -n -t cgroup -o "${grouping}" cgroup "${mountpoint_path}"

    if [[ "${grouping}" != "${sys}" ]]; then
      if [[ -L "${cgroup}/${sys}" ]]; then
        rm "${cgroup}/${sys}"
      fi

      ln -s "${mountpoint_path}" "${cgroup}/${sys}"
    fi
  done

  if ! [[ -d /sys/fs/cgroup/systemd ]]; then
    mkdir "${cgroup}/systemd"
    mount -t cgroup -o none,name=systemd cgroup "${cgroup}/systemd"
  fi
}

start_docker() {
  echo >&2 "Setting up Docker environment..."
  mkdir -p /var/log
  mkdir -p /var/run

  sanitize_cgroups

  if grep '/proc/sys\s\+\w\+\s\+ro,' /proc/mounts >/dev/null; then
    mount -o remount,rw /proc/sys
  fi

  local docker_opts="${DOCKER_OPTS}"

  if [[ "${docker_opts}" != *'--mtu'* ]]; then
    local route_iface
    route_iface="$(ip route get 8.8.8.8 | awk '{ print $5 }')"
    local mtu
    mtu="$(<"/sys/class/net/${route_iface}/mtu")"
    docker_opts+=" --mtu ${mtu}"
  fi

  if [[ "${docker_opts}" != *'--data-root'* ]] && [[ "${docker_opts}" != *'--graph'* ]]; then
    docker_opts+=' --data-root /scratch/docker'
  fi

  if [[ "${docker_opts}" != *'--storage-driver'* ]] && [[ "${docker_opts}" != *'-s '* ]]; then
    docker_opts+=' --storage-driver vfs'
  fi

  if [[ -n "${DOCKER_MIRROR}" ]]; then
    docker_opts+=" --registry-mirror ${DOCKER_MIRROR}"
  fi

  rm -f "${DOCKERD_PID_FILE}"
  touch "${DOCKERD_LOG_FILE}"

  echo >&2 "Starting Docker..."
  dockerd ${docker_opts} &>"${DOCKERD_LOG_FILE}" &
  echo "$!" > "${DOCKERD_PID_FILE}"
}

await_docker() {
  local timeout="${DOCKERD_TIMEOUT}"
  echo >&2 "Waiting ${timeout} seconds for Docker to be available..."
  local start=${SECONDS}
  timeout=$((timeout + start))

  until docker info &>/dev/null; do
    if (( SECONDS >= timeout )); then
      echo >&2 'Timed out trying to connect to docker daemon.'
      if [[ -f "${DOCKERD_LOG_FILE}" ]]; then
        echo >&2 '---DOCKERD LOGS---'
        cat >&2 "${DOCKERD_LOG_FILE}"
      fi
      exit 1
    fi

    if [[ -f "${DOCKERD_PID_FILE}" ]] && ! kill -0 "$(<"${DOCKERD_PID_FILE}")"; then
      echo >&2 'Docker daemon failed to start.'
      if [[ -f "${DOCKERD_LOG_FILE}" ]]; then
        echo >&2 '---DOCKERD LOGS---'
        cat >&2 "${DOCKERD_LOG_FILE}"
      fi
      exit 1
    fi

    sleep 1
  done

  local duration=$((SECONDS - start))
  echo >&2 "Docker available after ${duration} seconds."
}

stop_docker() {
  if ! [[ -f "${DOCKERD_PID_FILE}" ]]; then
    return 0
  fi

  local docker_pid
  docker_pid="$(<"${DOCKERD_PID_FILE}")"
  if [[ -z "${docker_pid}" ]]; then
    return 0
  fi

  echo >&2 "Terminating Docker daemon."
  kill -TERM "${docker_pid}"
  local start=${SECONDS}
  echo >&2 "Waiting for Docker daemon to exit..."
  wait "${docker_pid}"
  local duration=$((SECONDS - start))
  echo >&2 "Docker exited after ${duration} seconds."
}

if [[ ! -x "${BASE_ENTRYPOINT}" ]]; then
  echo >&2 "Base entrypoint not found: ${BASE_ENTRYPOINT}"
  exit 1
fi

start_docker
trap stop_docker EXIT
await_docker
setup_buildx
setup_binfmt

"${BASE_ENTRYPOINT}" "$@"
