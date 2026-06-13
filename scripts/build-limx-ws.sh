#!/usr/bin/env bash
set -euo pipefail

# Run this inside the ros-gazebo container:
#   ./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/build-limx-ws.sh

WORKSPACE="${LIMX_WS:-$HOME/limx_ws}"
SRC="${WORKSPACE}/src"
mkdir -p "${SRC}"

clone_once() {
  local url="$1"
  local dir="$2"
  local branch="${3:-}"

  if [[ -e "${SRC}/${dir}/.git" ]]; then
    echo "[SKIP] ${dir} already exists"
    return 0
  fi

  if [[ -n "${branch}" ]]; then
    git clone --branch "${branch}" "${url}" "${SRC}/${dir}"
  else
    git clone "${url}" "${SRC}/${dir}"
  fi
}

clone_once https://github.com/limxdynamics/robot-description.git robot-description
clone_once https://github.com/limxdynamics/limxsdk-lowlevel.git limxsdk-lowlevel
clone_once https://github.com/limxdynamics/robot-visualization.git robot-visualization
clone_once https://github.com/limxdynamics/tron1-gazebo-ros2.git tron1-gazebo-ros2 feature/humble

cd "${WORKSPACE}"
set +u
source /opt/ros/humble/setup.bash
set -u

# rosdep is useful but should not block first-time progress if a package index is temporarily unavailable.
rosdep update || true
rosdep install --from-paths src --ignore-src -r -y || true

colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release

echo

echo "[OK] limx workspace built at ${WORKSPACE}"
echo "Available pointfoot robot descriptions:"
tree -L 1 "${SRC}/robot-description/pointfoot" || true
