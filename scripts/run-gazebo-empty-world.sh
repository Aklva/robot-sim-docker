#!/usr/bin/env bash
set -euo pipefail

# Run inside ros-gazebo.
WORKSPACE="${LIMX_WS:-$HOME/limx_ws}"
cd "${WORKSPACE}"

set +u
source /opt/ros/humble/setup.bash
if [[ -f /usr/share/gazebo/setup.bash ]]; then
  source /usr/share/gazebo/setup.bash
fi
source install/setup.bash
set -u

export ROBOT_TYPE="${ROBOT_TYPE:-PF_P441C}"
exec ros2 launch pointfoot_gazebo empty_world.launch.py
