#!/usr/bin/env bash
set -euo pipefail

# Starts talker briefly and waits for a listener message in the same container.
set +u
source /opt/ros/humble/setup.bash
set -u

timeout 10s ros2 run demo_nodes_cpp talker > /tmp/talker.log 2>&1 &
talker_pid=$!
trap 'kill ${talker_pid} 2>/dev/null || true' EXIT

set +o pipefail
if timeout 10s ros2 run demo_nodes_cpp listener 2>&1 | tee /tmp/listener.log | grep -m1 "I heard"; then
  set -o pipefail
  echo "[OK] ROS 2 pub/sub works in this container."
else
  set -o pipefail
  echo "[ERROR] listener did not receive a talker message." >&2
  exit 1
fi
