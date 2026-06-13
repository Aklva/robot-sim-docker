#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

files=(-f compose.yml)
if [[ "${USE_NVIDIA_CDI:-1}" != "0" ]]; then
  files+=(-f compose.nvidia-cdi.yml)
fi

exec docker compose "${files[@]}" "$@"
