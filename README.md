# robot-sim-docker

Command workspace for running ROS 2 Humble with Gazebo Classic/LimX, ROS 2 Jazzy with Isaac Lab 2.3/Isaac Sim 5.1, LeIsaac, and MuJoCo from containers on a NixOS host.

The host stays lean: Docker, NVIDIA driver/toolkit/CDI, and X11 helpers live on NixOS; ROS, Gazebo, Isaac, Conda-style Python stacks, and MuJoCo GUI workloads stay inside containers.

## Workspace Map

```text
robot-sim-docker/
├─ compose.yml
├─ compose.nvidia-cdi.yml
├─ containers/ros-gazebo/Dockerfile
├─ scripts/
├─ overrides/
├─ nixos/
├─ IsaacLab/                 # submodule: official Isaac Lab
├─ leisaac/                  # submodule: LeIsaac
├─ ros_ws/src/
│  ├─ robot-description/     # submodule
│  ├─ limxsdk-lowlevel/      # submodule
│  ├─ robot-visualization/   # submodule
│  └─ tron1-gazebo-ros2/     # submodule, feature/humble
├─ mujoco/                   # downloaded MuJoCo standalone files
└─ isaac-cache/              # Isaac cache bind-mount placeholders
```

Generated outputs are ignored: `ros_ws/build/`, `ros_ws/install/`, `ros_ws/log/`, MuJoCo release archives/extracts, Isaac cache contents, and `.env`.

## Command Index

### Check The Host

```bash
docker compose version
nvidia-smi
nvidia-ctk cdi list || true
docker run --rm --device nvidia.com/gpu=all ubuntu:22.04 nvidia-smi
```

For a host-side OpenGL check without globally installing `mesa-demos`:

```bash
nix shell nixpkgs#mesa-demos -c glxinfo -B
```

### Refresh This Workspace

```bash
git submodule update --init --recursive
cp -n .env.example .env
```

Edit `.env` when you want to change the container UID/GID, ROS domain, robot type, Isaac Lab ref, or MuJoCo version.

### Prepare Or Revoke GUI Access

```bash
./scripts/prepare-x11.sh
```

If cookie-based X11 auth fails under Wayland/XWayland:

```bash
X11_USE_XHOST=1 ./scripts/prepare-x11.sh
```

Revoke the `xhost` fallback:

```bash
./scripts/revoke-x11.sh
```

### Validate Compose

```bash
bash -n scripts/*.sh
./scripts/compose.sh config
```

The merged `ros-gazebo` service should include:

```yaml
devices:
  - nvidia.com/gpu=all
```

### Build The ROS/Gazebo Image

```bash
./scripts/compose.sh build ros-gazebo
```

### Enter The ROS/Gazebo Container

```bash
./scripts/compose.sh run --rm ros-gazebo bash
```

### Check ROS 2 Pub/Sub

```bash
./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/check-ros2-talk-listen.sh
```

### Check GUI Rendering From The Container

```bash
./scripts/check-gui.sh
```

This runs `glxinfo -B` and a short `xeyes` smoke test from the `ros-gazebo` container.

### Build The LimX Workspace

```bash
git submodule update --init --recursive \
  ros_ws/src/robot-description \
  ros_ws/src/limxsdk-lowlevel \
  ros_ws/src/robot-visualization \
  ros_ws/src/tron1-gazebo-ros2

./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/build-limx-ws.sh
```

The build script still clones missing sources as a fallback, but this workspace normally uses submodules.

### Patch LimX Gazebo Support Mode

```bash
./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/patch-empty-world-use-support.sh
```

This patches generated and source `empty_world.launch.py` files so `use_support=true`.

### Launch LimX In Gazebo

```bash
./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/run-gazebo-empty-world.sh
```

Change the robot in `.env`:

```dotenv
ROBOT_TYPE=PF_P441C
```

### Prepare Isaac Lab Overrides

```bash
git submodule update --init IsaacLab
./scripts/bootstrap-isaaclab.sh
```

This keeps upstream Isaac Lab files in the submodule and copies only local override/env files into `IsaacLab/docker/`.

The tested compatibility set is pinned by immutable commit IDs and base-image
digests in `versions.env`. Verify it without building:

```bash
./scripts/check-reproducibility.sh --registry
```

`start-isaaclab-ros2.sh` runs this check automatically and refuses to build if
the upstream image tag has moved or either submodule is at a different commit.
For an intentional offline start using an already cached image, set
`REPRODUCIBILITY_VERIFY_REGISTRY=0`.

### Inspect Isaac Lab Merged Compose

```bash
cd IsaacLab
../scripts/isaaclab-container.sh config ros2 \
  --files docker-compose.nixos-cdi.leisaac.patch.yaml \
  --env-files .env.leisaac
```

Check that:

- service name is `isaac-lab-ros2`
- service-level `deploy:` is absent/reset
- `devices:` contains `nvidia.com/gpu=all`
- `./leisaac` mounts to `/workspace/leisaac`
- setup scripts mount read-only under `/workspace/`

### Start Isaac Lab ROS 2

```bash
./scripts/start-isaaclab-ros2.sh
```

By default, Isaac Lab invokes Compose with `--build`. Docker checks the build
inputs on every start and reports unchanged steps as `CACHED`; it does not
execute those steps again. To skip even this cache check and use the existing
local image explicitly:

```bash
./scripts/start-isaaclab-ros2.sh --no-build
```

### Enter Isaac Lab ROS 2

```bash
./scripts/enter-isaaclab-ros2.sh
```

This refreshes the stable `/tmp/.docker.xauth` file and enters the running
container directly; it does not use Isaac Lab's ephemeral Xauthority state.

### Stop Isaac Lab ROS 2

```bash
./scripts/stop-isaaclab-ros2.sh
```

### Install LeIsaac Inside Isaac Lab

```bash
git submodule update --init --recursive leisaac
./scripts/enter-isaaclab-ros2.sh
bash /workspace/setup-leisaac-inside-isaaclab.sh
```

`./scripts/bootstrap-leisaac-host.sh` remains available for non-submodule worktrees.

### Install MuJoCo Python Inside Isaac Lab

```bash
./scripts/enter-isaaclab-ros2.sh
bash /workspace/setup-mujoco-python-inside-isaaclab.sh
```

### Download MuJoCo Standalone Into The ROS/Gazebo Container Workspace

```bash
./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/setup-mujoco-standalone.sh
```

### Run MuJoCo Standalone GUI

```bash
./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/run-mujoco-simulate.sh
```

Run a specific model:

```bash
./scripts/compose.sh run --rm ros-gazebo \
  /opt/robot-sim/scripts/run-mujoco-simulate.sh \
  /home/ros/mujoco/mujoco-3.4.0/model/humanoid/humanoid.xml
```

### Clean Generated Workspace Outputs

```bash
rm -rf ros_ws/build ros_ws/install ros_ws/log
rm -rf mujoco/mujoco-* mujoco/*.tar.gz
find isaac-cache -mindepth 2 ! -name .gitkeep -delete
```

## Notes

- Use `docker compose`, not the legacy standalone `docker-compose`.
- Prefer NVIDIA CDI on NixOS: `nvidia.com/gpu=all`.
- Do not move ROS, Gazebo, Conda, Isaac Lab, or MuJoCo GUI packages into the global NixOS environment.
- The `ros-gazebo` image may contain `mesa-utils`; the host should use `nix shell nixpkgs#mesa-demos -c glxinfo -B` only when needed.
- Isaac Lab is driven through official `docker/container.py`; local differences live in `overrides/` and are re-applied by `./scripts/bootstrap-isaaclab.sh`.
