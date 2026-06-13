#!/usr/bin/env bash
set -euo pipefail

# Run inside ros-gazebo after setup-mujoco-standalone.sh.
MUJOCO_VERSION="${MUJOCO_VERSION:-3.4.0}"
DEST="${MUJOCO_DEST:-$HOME/mujoco}"
SIM="${DEST}/mujoco-${MUJOCO_VERSION}/bin/simulate"
MODEL="${1:-${DEST}/mujoco-${MUJOCO_VERSION}/model/humanoid/humanoid.xml}"

if [[ ! -x "${SIM}" ]]; then
  echo "[ERROR] ${SIM} not found. Run setup-mujoco-standalone.sh first." >&2
  exit 1
fi

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-$(id -u)}"
mkdir -p "${XDG_RUNTIME_DIR}"
chmod 0700 "${XDG_RUNTIME_DIR}"

exec "${SIM}" "${MODEL}"
