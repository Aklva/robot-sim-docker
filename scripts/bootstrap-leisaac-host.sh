#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

set -a
[[ -f .env ]] && source .env
source versions.env
set +a

LEISAAC_DIR="${LEISAAC_DIR:-leisaac}"
LEISAAC_REPO="${LEISAAC_REPO:-https://github.com/LightwheelAI/leisaac.git}"

if [[ ! -d "${LEISAAC_DIR}/source/leisaac" ]] \
  && git config -f .gitmodules --get "submodule.${LEISAAC_DIR}.url" >/dev/null 2>&1; then
  git submodule update --init --recursive "${LEISAAC_DIR}"
fi

if [[ -d "${LEISAAC_DIR}/source/leisaac" ]]; then
  if [[ -e "${LEISAAC_DIR}/.git" ]]; then
    git -C "${LEISAAC_DIR}" checkout "${LEISAAC_REF}"
  fi
  ./scripts/check-reproducibility.sh
  echo "[OK] ${LEISAAC_DIR} is at the pinned LeIsaac commit."
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
git -C "${LEISAAC_DIR}" checkout "${LEISAAC_REF}"
git -C "${LEISAAC_DIR}" submodule update --init --recursive
echo "[OK] cloned LeIsaac into ${LEISAAC_DIR}"
