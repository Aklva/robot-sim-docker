#!/usr/bin/env bash
set -euo pipefail

if command -v xhost >/dev/null 2>&1; then
  xhost -local:docker >/dev/null || true
  echo "[OK] revoked xhost local docker access if it had been enabled."
else
  echo "[INFO] xhost not available; nothing to revoke."
fi
