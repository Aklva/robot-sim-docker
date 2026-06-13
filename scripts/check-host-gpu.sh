#!/usr/bin/env bash
set -euo pipefail

echo "== Host NVIDIA =="
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi
else
  echo "[WARN] nvidia-smi not found on host PATH."
fi

echo

echo "== Docker CDI check =="
docker run --rm --device nvidia.com/gpu=all ubuntu:22.04 bash -lc \
  'if command -v nvidia-smi >/dev/null 2>&1; then nvidia-smi; else echo "nvidia-smi not in image; checking device files"; ls -l /dev/nvidia* 2>/dev/null || true; fi'
