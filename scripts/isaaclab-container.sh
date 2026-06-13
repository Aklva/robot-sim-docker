#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

set -a
[[ -f .env ]] && source .env
set +a

ISAACLAB_DIR="${ISAACLAB_DIR:-IsaacLab}"
if [[ ! -f "${ISAACLAB_DIR}/docker/container.py" ]]; then
  echo "[ERROR] ${ISAACLAB_DIR}/docker/container.py not found. Run ./scripts/bootstrap-isaaclab.sh first." >&2
  exit 1
fi

cd "${ISAACLAB_DIR}"

if command -v python3 >/dev/null 2>&1; then
  exec ./docker/container.py "$@"
fi

if command -v nix >/dev/null 2>&1; then
  exec nix shell nixpkgs#python3 -c ./docker/container.py "$@"
fi

cat >&2 <<'MSG'
[ERROR] python3 is not available, and nix was not found to provide a temporary Python shell.
On NixOS, run through: nix shell nixpkgs#python3 -c ./docker/container.py ...
MSG
exit 1
