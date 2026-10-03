#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

set -a
[[ -f .env ]] && source .env
set +a

# Isaac Lab's x11.yaml is merged after our override and forwards the host TERM.
# The image has xterm-256color terminfo, but not Ghostty's xterm-ghostty entry.
export TERM=xterm-256color

ISAACLAB_DIR="${ISAACLAB_DIR:-IsaacLab}"
skip_build=0
if [[ "${1:-}" == "--no-build" ]]; then
  skip_build=1
  shift
fi

if [[ ! -f "${ISAACLAB_DIR}/docker/docker-compose.nixos-cdi.leisaac.patch.yaml" ]] ||
   [[ ! -f "${ISAACLAB_DIR}/docker/Dockerfile.ros2.jazzy" ]]; then
  ./scripts/bootstrap-isaaclab.sh
fi

if [[ "${REPRODUCIBILITY_VERIFY_REGISTRY:-1}" == "1" ]]; then
  ./scripts/check-reproducibility.sh --registry
else
  ./scripts/check-reproducibility.sh
fi

# /tmp is cleared on reboot. Create the bind-mount source before either
# startup path reaches Docker; otherwise Docker creates a directory at the
# missing file path and the container can no longer mount Xauthority.
if [[ "${ISAACLAB_X11:-1}" == "1" ]]; then
  ./scripts/prepare-x11.sh
else
  : > "${XAUTH:-/tmp/.docker.xauth}"
fi

# Optional fast path. The default below intentionally preserves Isaac Lab's
# upstream `--build` behavior: Docker checks inputs on every start and reuses
# cached layers when nothing changed.
if (( skip_build == 1 )); then
  if ! docker image inspect isaac-lab-ros2 >/dev/null 2>&1; then
    echo "[ERROR] isaac-lab-ros2 does not exist; start once without --no-build." >&2
    exit 1
  fi
  cd "${ISAACLAB_DIR}/docker"
  exec docker compose \
    --file docker-compose.yaml \
    --file docker-compose.nixos-cdi.leisaac.patch.yaml \
    --profile ros2 \
    --env-file .env.base \
    --env-file .env.ros2 \
    --env-file .env.leisaac \
    up --detach --no-build --remove-orphans isaac-lab-ros2
fi

exec ./scripts/isaaclab-container.sh start ros2 \
  --files docker-compose.nixos-cdi.leisaac.patch.yaml \
  --env-files .env.leisaac \
  "$@"
