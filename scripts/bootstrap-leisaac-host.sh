#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

set -a
[[ -f .env ]] && source .env
set +a

LEISAAC_DIR="${LEISAAC_DIR:-leisaac}"
LEISAAC_REPO="${LEISAAC_REPO:-https://github.com/LightwheelAI/leisaac.git}"

if [[ ! -d "${LEISAAC_DIR}/source/leisaac" ]] \
  && git config -f .gitmodules --get "submodule.${LEISAAC_DIR}.url" >/dev/null 2>&1; then
  git submodule update --init --recursive "${LEISAAC_DIR}"
fi

if [[ -d "${LEISAAC_DIR}/source/leisaac" ]]; then
  echo "[OK] ${LEISAAC_DIR} already looks like a LeIsaac checkout."
  exit 0
fi

if [[ -n "$(find "${LEISAAC_DIR}" -mindepth 1 ! -name .gitkeep -print -quit 2>/dev/null || true)" ]]; then
  cat >&2 <<MSG
[ERROR] ${LEISAAC_DIR} is not empty, but source/leisaac was not found.
        Move your existing files aside, or unpack leisaac.zip so that:
          ${LEISAAC_DIR}/source/leisaac
        exists.
MSG
  exit 1
fi

rm -rf "${LEISAAC_DIR}"
git clone --recursive "${LEISAAC_REPO}" "${LEISAAC_DIR}"
echo "[OK] cloned LeIsaac into ${LEISAAC_DIR}"
