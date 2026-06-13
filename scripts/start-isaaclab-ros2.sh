#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

set -a
[[ -f .env ]] && source .env
set +a

ISAACLAB_DIR="${ISAACLAB_DIR:-IsaacLab}"

if [[ ! -f "${ISAACLAB_DIR}/docker/docker-compose.nixos-cdi.leisaac.patch.yaml" ]]; then
  ./scripts/bootstrap-isaaclab.sh
fi

exec ./scripts/isaaclab-container.sh start ros2 \
  --files docker-compose.nixos-cdi.leisaac.patch.yaml \
  --env-files .env.leisaac \
  "$@"
