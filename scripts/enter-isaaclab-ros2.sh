#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"
set -a
[[ -f .env ]] && source .env
set +a

container_name="isaac-lab-ros2${DOCKER_NAME_SUFFIX:-}"

if ! docker container inspect "${container_name}" >/dev/null 2>&1; then
  echo "[ERROR] ${container_name} does not exist. Run ./scripts/start-isaaclab-ros2.sh first." >&2
  exit 1
fi

if [[ "$(docker container inspect -f '{{.State.Status}}' "${container_name}")" != "running" ]]; then
  echo "[ERROR] ${container_name} is not running. Run ./scripts/start-isaaclab-ros2.sh first." >&2
  exit 1
fi

if [[ "${ISAACLAB_X11:-1}" == "1" ]]; then
  ./scripts/prepare-x11.sh
fi

# The local Compose override mounts a stable /tmp/.docker.xauth path. Bypass
# Isaac Lab's upstream enter command, which expects its own ephemeral xauth
# path and incorrectly asks for an image rebuild after that file is removed.
exec docker exec --interactive --tty \
  -e "DISPLAY=${DISPLAY:-:0}" \
  -e TERM=xterm-256color \
  -e XAUTHORITY=/tmp/.docker.xauth \
  "${container_name}" \
  bash "$@"
