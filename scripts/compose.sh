#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

set -a
source versions.env
ROS_GAZEBO_BASE_IMAGE="${ROS_GAZEBO_BASE_IMAGE}:${ROS_GAZEBO_BASE_TAG}@${ROS_GAZEBO_BASE_DIGEST}"
set +a

files=(-f compose.yml)
if [[ "${USE_NVIDIA_CDI:-1}" != "0" ]]; then
  files+=(-f compose.nvidia-cdi.yml)
fi

exec docker compose "${files[@]}" "$@"
