#!/usr/bin/env bash
set -euo pipefail

# Prepare Xauthority for containers. Works for X11 and most Wayland sessions
# through XWayland as long as DISPLAY is set.

if [[ -z "${DISPLAY:-}" ]]; then
  echo "[ERROR] DISPLAY is not set. Start this from a graphical terminal." >&2
  exit 1
fi

XAUTH_FILE="${XAUTH:-/tmp/.docker.xauth}"
touch "${XAUTH_FILE}"

if ! command -v xauth >/dev/null 2>&1; then
  cat >&2 <<'MSG'
[ERROR] xauth is not available on the host.
On NixOS, add xorg.xauth globally or run this script from:
  nix shell nixpkgs#xorg.xauth -c ./scripts/prepare-x11.sh
MSG
  exit 1
fi

# The ffff substitution makes the cookie family-agnostic for local containers.
if xauth nlist "${DISPLAY}" | sed -e 's/^..../ffff/' | xauth -f "${XAUTH_FILE}" nmerge -; then
  chmod 0644 "${XAUTH_FILE}"
  echo "[OK] Xauthority written: ${XAUTH_FILE}"
else
  echo "[WARN] xauth did not return a cookie for DISPLAY=${DISPLAY}." >&2
  echo "       If GUI fails, try: X11_USE_XHOST=1 ./scripts/prepare-x11.sh" >&2
fi

if [[ "${X11_USE_XHOST:-0}" == "1" ]]; then
  if command -v xhost >/dev/null 2>&1; then
    xhost +local:docker >/dev/null
    echo "[OK] xhost allowed local docker clients. Revoke with ./scripts/revoke-x11.sh"
  else
    echo "[WARN] xhost not found; skipping xhost relaxation." >&2
  fi
fi
