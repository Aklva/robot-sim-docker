#!/usr/bin/env bash
set -euo pipefail

# Run inside ros-gazebo. The ./mujoco host directory is bind-mounted to ~/mujoco.

MUJOCO_VERSION="${MUJOCO_VERSION:-3.4.0}"
DEST="${MUJOCO_DEST:-$HOME/mujoco}"
ARCHIVE="mujoco-${MUJOCO_VERSION}-linux-x86_64.tar.gz"
URL="https://github.com/google-deepmind/mujoco/releases/download/${MUJOCO_VERSION}/${ARCHIVE}"

mkdir -p "${DEST}"
cd "${DEST}"

if [[ -x "${DEST}/mujoco-${MUJOCO_VERSION}/bin/simulate" ]]; then
  echo "[OK] MuJoCo ${MUJOCO_VERSION} already exists under ${DEST}"
  exit 0
fi

if [[ ! -f "${ARCHIVE}" ]]; then
  echo "[INFO] downloading ${URL}"
  if command -v curl >/dev/null 2>&1; then
    curl -L -o "${ARCHIVE}" "${URL}"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "${ARCHIVE}" "${URL}"
  else
    echo "[ERROR] curl/wget not found" >&2
    exit 1
  fi
fi

tar -xzf "${ARCHIVE}"
echo "[OK] extracted MuJoCo to ${DEST}/mujoco-${MUJOCO_VERSION}"
