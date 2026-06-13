#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

set -a
[[ -f .env ]] && source .env
set +a

ISAACLAB_REPO="${ISAACLAB_REPO:-https://github.com/isaac-sim/IsaacLab.git}"
ISAACLAB_REF="${ISAACLAB_REF:-v2.3.0}"
ISAACLAB_DIR="${ISAACLAB_DIR:-IsaacLab}"
ISAACLAB_X11="${ISAACLAB_X11:-1}"

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] docker command not found." >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "[ERROR] docker compose plugin is not available." >&2
  exit 1
fi

if [[ ! -e "${ISAACLAB_DIR}/.git" ]]; then
  if git config -f .gitmodules --get "submodule.${ISAACLAB_DIR}.url" >/dev/null 2>&1; then
    git submodule update --init "${ISAACLAB_DIR}"
  else
    git clone "${ISAACLAB_REPO}" "${ISAACLAB_DIR}"
  fi
fi

cd "${ISAACLAB_DIR}"
git fetch --tags --quiet || true
git checkout "${ISAACLAB_REF}"

cd "${ROOT_DIR}"
cp overrides/isaaclab-nixos-cdi.leisaac.patch.yaml \
  "${ISAACLAB_DIR}/docker/docker-compose.nixos-cdi.leisaac.patch.yaml"
cp overrides/isaaclab-leisaac.env \
  "${ISAACLAB_DIR}/docker/.env.leisaac"

# Pre-answer Isaac Lab's X11 prompt when requested.
# container.py uses a ConfigParser-style docker/.container.cfg with section [X11].
if [[ "${ISAACLAB_X11}" == "1" ]]; then
  cat > "${ISAACLAB_DIR}/docker/.container.cfg" <<'CFG'
[X11]
x11_forwarding_enabled = 1
CFG
  echo "[OK] Isaac Lab X11 forwarding pre-enabled in ${ISAACLAB_DIR}/docker/.container.cfg"
fi

cat <<MSG
[OK] Isaac Lab prepared at ${ISAACLAB_DIR}
Next:
  ./scripts/start-isaaclab-ros2.sh
  ./scripts/enter-isaaclab-ros2.sh
Inside the container, install LeIsaac with:
  bash /workspace/setup-leisaac-inside-isaaclab.sh
MSG
