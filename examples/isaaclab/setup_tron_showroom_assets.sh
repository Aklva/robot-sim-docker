#!/usr/bin/env bash
set -euo pipefail

# data_storage is a persistent Docker volume in the Isaac Lab container.
asset_root="${TRON_SHOWROOM_ASSET_ROOT:-/workspace/isaaclab/data_storage/tron_showroom_assets}"
mkdir -p "${asset_root}"

clone_at_commit() {
    local repository="$1"
    local destination="$2"
    local commit="$3"

    if [[ ! -d "${destination}/.git" ]]; then
        git clone --filter=blob:none --no-checkout "${repository}" "${destination}"
    fi
    git -C "${destination}" fetch --depth 1 origin "${commit}"
    git -C "${destination}" checkout --detach "${commit}"
}

# Pin every third-party input so repeated setup produces the same showroom.
clone_at_commit \
    https://github.com/limxdynamics/humanoid-description.git \
    "${asset_root}/humanoid-description" \
    97b2174054103f9f7085ec1e3533972e4d0f2a50
clone_at_commit \
    https://github.com/limxdynamics/tron1-rl-isaaclab.git \
    "${asset_root}/tron1-rl-isaaclab" \
    307145edfe95f49c45fd9ccd090ab950e8884b33
clone_at_commit \
    https://github.com/BoosterRobotics/booster_assets.git \
    "${asset_root}/booster_assets" \
    3c2dfa99e09beddf092e0d6521dbbcec7e7903ed

echo "[INFO] Showroom assets are ready under ${asset_root}"
