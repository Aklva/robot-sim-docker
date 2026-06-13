#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

./scripts/compose.sh run --rm ros-gazebo bash -lc '
  set -e
  echo "DISPLAY=$DISPLAY"
  echo "XAUTHORITY=$XAUTHORITY"
  glxinfo -B
  echo "Launching xeyes for a short GUI smoke test..."
  timeout 5s xeyes || true
'
