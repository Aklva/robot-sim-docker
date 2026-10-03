# Copyright (c) 2026
# SPDX-License-Identifier: BSD-3-Clause
"""Display G1, Oli, TRON1, and BOOSTER K1 in one Isaac Lab scene."""

from __future__ import annotations

import argparse
from pathlib import Path

from isaaclab.app import AppLauncher


parser = argparse.ArgumentParser(description="Show all four TRON KK robot models in one scene.")
parser.add_argument(
    "--asset-root",
    type=Path,
    default=Path("/workspace/isaaclab/data_storage/tron_showroom_assets"),
    help="Directory created by setup_tron_showroom_assets.sh.",
)
parser.add_argument("--max-steps", type=int, default=0, help="Exit after N frames; 0 keeps the GUI open.")
AppLauncher.add_app_launcher_args(parser)
args_cli = parser.parse_args()

app_launcher = AppLauncher(args_cli)
simulation_app = app_launcher.app

import isaacsim.core.utils.prims as prim_utils

import isaaclab.sim as sim_utils
from isaaclab.utils.assets import ISAACLAB_NUCLEUS_DIR


def require_file(path: Path, model_name: str) -> str:
    """Return an absolute asset path, with an actionable setup error."""
    if not path.is_file():
        raise FileNotFoundError(
            f"{model_name} asset was not found: {path}\n"
            "Run: bash scripts/demos/setup_tron_showroom_assets.sh"
        )
    return str(path.resolve())


def spawn_fixed_usd(prim_path: str, usd_path: str, position: tuple[float, float, float]) -> None:
    """Spawn an articulated USD and pin its root for showroom display."""
    cfg = sim_utils.UsdFileCfg(
        usd_path=usd_path,
        rigid_props=sim_utils.RigidBodyPropertiesCfg(disable_gravity=True),
        articulation_props=sim_utils.ArticulationRootPropertiesCfg(
            fix_root_link=True,
            enabled_self_collisions=False,
        ),
    )
    cfg.func(prim_path, cfg, translation=position)


def design_scene(asset_root: Path) -> None:
    """Create the showroom and place the four robots from left to right."""
    ground_cfg = sim_utils.GroundPlaneCfg(size=(14.0, 8.0))
    ground_cfg.func("/World/Ground", ground_cfg)
    light_cfg = sim_utils.DomeLightCfg(intensity=2500.0, color=(0.85, 0.85, 0.85))
    light_cfg.func("/World/DomeLight", light_cfg)
    key_light_cfg = sim_utils.DistantLightCfg(intensity=1500.0, angle=0.5)
    key_light_cfg.func("/World/KeyLight", key_light_cfg, orientation=(0.89, 0.37, 0.10, 0.24))
    prim_utils.create_prim("/World/Robots", "Xform")

    oli_usd = require_file(
        asset_root / "humanoid-description/HU_D04_description/usd/HU_D04_01.usd", "Oli"
    )
    tron1_usd = require_file(
        asset_root
        / "tron1-rl-isaaclab/exts/bipedal_locomotion/bipedal_locomotion/assets/usd/PF_TRON1A/PF_TRON1A.usd",
        "TRON1",
    )
    k1_urdf = require_file(asset_root / "booster_assets/robots/K1/K1_locomotion.urdf", "BOOSTER K1")
    k1_usd_dir = asset_root / "generated/K1_locomotion"
    k1_usd_dir.mkdir(parents=True, exist_ok=True)

    spawn_fixed_usd(
        "/World/Robots/G1",
        f"{ISAACLAB_NUCLEUS_DIR}/Robots/Unitree/G1/g1.usd",
        (-3.6, 0.0, 0.0),
    )
    spawn_fixed_usd("/World/Robots/Oli", oli_usd, (-1.2, 0.0, 0.0))
    spawn_fixed_usd("/World/Robots/TRON1", tron1_usd, (1.2, 0.0, 0.0))

    # K1 is distributed as URDF. Isaac Lab converts it once and reuses the USD.
    k1_cfg = sim_utils.UrdfFileCfg(
        asset_path=k1_urdf,
        usd_dir=str(k1_usd_dir),
        usd_file_name="K1_locomotion.usd",
        fix_base=True,
        merge_fixed_joints=False,
        force_usd_conversion=False,
        joint_drive=sim_utils.UrdfFileCfg.JointDriveCfg(
            target_type="position",
            gains=sim_utils.UrdfFileCfg.JointDriveCfg.PDGainsCfg(stiffness=0.0, damping=0.0),
        ),
    )
    k1_cfg.func("/World/Robots/BOOSTER_K1", k1_cfg, translation=(3.6, 0.0, 0.0))

    print("[INFO] Loaded: G1 | Oli (HU_D04) | TRON1 (PF_TRON1A) | BOOSTER K1 (22 DoF)", flush=True)


def main() -> None:
    sim_cfg = sim_utils.SimulationCfg(dt=1.0 / 60.0, device=args_cli.device)
    sim = sim_utils.SimulationContext(sim_cfg)
    sim.set_camera_view(eye=(9.5, -11.0, 5.0), target=(0.0, 0.0, 1.0))
    design_scene(args_cli.asset_root.expanduser().resolve())
    step = 0
    while simulation_app.is_running() and (args_cli.max_steps <= 0 or step < args_cli.max_steps):
        sim.render()
        step += 1


if __name__ == "__main__":
    try:
        main()
    finally:
        simulation_app.close()
