#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if [[ ! -f versions.env ]]; then
  echo "[ERROR] versions.env is missing." >&2
  exit 1
fi

set -a
source versions.env
set +a

fail=0
check_equal() {
  local label="$1" actual="$2" expected="$3"
  if [[ "${actual}" != "${expected}" ]]; then
    printf '[ERROR] %s: expected %s, got %s\n' "${label}" "${expected}" "${actual}" >&2
    fail=1
  fi
}

for value in ISAACLAB_REF LEISAAC_REF ISAACSIM_IMAGE ISAACSIM_VERSION \
  ISAACSIM_IMAGE_DIGEST ISAACLAB_UBUNTU_CODENAME ISAACLAB_ROS_DISTRO ROS_APT_SUITE; do
  if [[ -z "${!value:-}" ]]; then
    echo "[ERROR] versions.env does not define ${value}." >&2
    fail=1
  fi
done

for value in ROS_GAZEBO_BASE_IMAGE ROS_GAZEBO_BASE_TAG ROS_GAZEBO_BASE_DIGEST; do
  if [[ -z "${!value:-}" ]]; then
    echo "[ERROR] versions.env does not define ${value}." >&2
    fail=1
  fi
done

if [[ "${ISAACLAB_REF:-}" != "${ISAACLAB_REF,,}" || ! "${ISAACLAB_REF:-}" =~ ^[0-9a-f]{40}$ ]]; then
  echo "[ERROR] ISAACLAB_REF must be a full 40-character commit ID." >&2
  fail=1
fi
if [[ "${LEISAAC_REF:-}" != "${LEISAAC_REF,,}" || ! "${LEISAAC_REF:-}" =~ ^[0-9a-f]{40}$ ]]; then
  echo "[ERROR] LEISAAC_REF must be a full 40-character commit ID." >&2
  fail=1
fi

if [[ -e IsaacLab/.git ]]; then
  check_equal "IsaacLab commit" "$(git -C IsaacLab rev-parse HEAD)" "${ISAACLAB_REF}"
  upstream_sim_version="$(sed -n 's/^ISAACSIM_VERSION=//p' IsaacLab/docker/.env.base)"
  check_equal "Isaac Sim version" "${upstream_sim_version}" "${ISAACSIM_VERSION}"
  for pair in \
    "overrides/Dockerfile.ros2.jazzy:IsaacLab/docker/Dockerfile.ros2.jazzy" \
    "overrides/isaaclab-leisaac.env:IsaacLab/docker/.env.leisaac" \
    "overrides/isaaclab-nixos-cdi.leisaac.patch.yaml:IsaacLab/docker/docker-compose.nixos-cdi.leisaac.patch.yaml"; do
    source_file="${pair%%:*}"
    generated_file="${pair#*:}"
    if [[ ! -f "${generated_file}" ]] || ! cmp -s "${source_file}" "${generated_file}"; then
      echo "[ERROR] ${generated_file} is stale; run ./scripts/bootstrap-isaaclab.sh." >&2
      fail=1
    fi
  done
fi

if [[ -e leisaac/.git ]]; then
  check_equal "LeIsaac commit" "$(git -C leisaac rev-parse HEAD)" "${LEISAAC_REF}"
fi

dockerfile=overrides/Dockerfile.ros2.jazzy
if [[ -f "${dockerfile}" ]]; then
  grep -q "ros-${ISAACLAB_ROS_DISTRO}-" "${dockerfile}" || {
    echo "[ERROR] ${dockerfile} does not install ROS ${ISAACLAB_ROS_DISTRO}." >&2
    fail=1
  }
  grep -q "ubuntu ${ROS_APT_SUITE} main" "${dockerfile}" || {
    echo "[ERROR] ${dockerfile} does not use the ${ROS_APT_SUITE} ROS APT suite." >&2
    fail=1
  }
fi

if [[ "${1:-}" == "--registry" ]]; then
  command -v docker >/dev/null || {
    echo "[ERROR] docker is required for registry digest verification." >&2
    exit 1
  }
  actual_digest="$(docker buildx imagetools inspect \
    "${ISAACSIM_IMAGE}:${ISAACSIM_VERSION}" --format '{{.Manifest.Digest}}')"
  check_equal "Isaac Sim registry digest" "${actual_digest}" "${ISAACSIM_IMAGE_DIGEST}"
  actual_digest="$(docker buildx imagetools inspect \
    "${ROS_GAZEBO_BASE_IMAGE}:${ROS_GAZEBO_BASE_TAG}" --format '{{.Manifest.Digest}}')"
  check_equal "ROS/Gazebo registry digest" "${actual_digest}" "${ROS_GAZEBO_BASE_DIGEST}"
fi

(( fail == 0 )) || exit 1
echo "[OK] Reproducibility manifest is internally consistent."
