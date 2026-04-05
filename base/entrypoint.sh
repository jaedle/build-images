#!/usr/bin/env bash

set -eu -o pipefail

if [[ -n "${WORKDIR}" ]]; then
  TARGET_DIR="./${WORKDIR}"
  echo "[entrypoint] changing to directory: ${TARGET_DIR}"
  if [[ ! -d "${TARGET_DIR}" ]]; then
    echo "[entrypoint] error: directory '${TARGET_DIR}' does not exist" >&2
    exit 1
  fi
  cd "${TARGET_DIR}"
fi

if [[ -f ".mise.toml" ]] || [[ -f "mise.toml" ]]; then
  echo "[entrypoint] mise config found, running mise install"
  mise trust --yes
  mise install
else
  echo "[entrypoint] no mise config found, skipping mise install"
fi

for cmd in "$@"; do
  mise exec -- bash -c "$cmd"
done
