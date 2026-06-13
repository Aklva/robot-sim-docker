#!/usr/bin/env bash
set -euo pipefail

# Run inside the Isaac Lab ROS2 container:
#   bash /workspace/setup-leisaac-inside-isaaclab.sh

LEISAAC_PATH="${LEISAAC_PATH:-/workspace/leisaac}"

if [[ ! -d "${LEISAAC_PATH}/source/leisaac" ]]; then
  cat >&2 <<MSG
[ERROR] ${LEISAAC_PATH}/source/leisaac was not found.
On the host, run:
  ./scripts/bootstrap-leisaac-host.sh
or unpack your leisaac.zip into ./leisaac so that ./leisaac/source/leisaac exists.
MSG
  exit 1
fi

cd "${LEISAAC_PATH}"
python -m pip install --upgrade pip
python -m pip install -e source/leisaac
python -m pip install pynput pyserial deepdiff feetech-servo-sdk

python - <<'PY'
import importlib.util
print("LeIsaac import path present:", importlib.util.find_spec("leisaac") is not None)
PY
