#!/usr/bin/env bash
set -euo pipefail

# Run inside the Isaac Lab ROS2 container if you want the Python MuJoCo binding there.
# Isaac Lab's Docker image aliases python to /isaac-sim/python.sh.

python -m pip install --upgrade pip
python -m pip install "mujoco==${MUJOCO_VERSION:-3.4.0}"
python - <<'PY'
import mujoco
print("MuJoCo:", mujoco.__version__)
PY
