# robot-sim-docker

NixOS host + Docker containers for a ROS 2 Humble / Gazebo / Isaac Lab / LeIsaac / MuJoCo development environment.

The design goal is to keep NixOS clean and let Ubuntu/NVIDIA containers carry the non-Nix robotics stack:

- `ros-gazebo`: Ubuntu 22.04 / ROS 2 Humble / Gazebo Classic / LimX workspace / standalone MuJoCo GUI.
- `IsaacLab`: official Isaac Lab Docker workflow, checked out at `v2.3.0` by default, using the `ros2` image extension.
- `leisaac`: mounted into the Isaac Lab container from the project root.

## Directory layout

```text
robot-sim-docker/
├─ compose.yml
├─ compose.nvidia-cdi.yml
├─ containers/
│  └─ ros-gazebo/
│     └─ Dockerfile
├─ nixos/
│  ├─ configuration-fragment.nix
│  └─ host-notes.md
├─ overrides/
│  ├─ isaaclab-leisaac.env
│  └─ isaaclab-nixos-cdi.leisaac.patch.yaml
├─ prompts/
│  └─ codex.md
├─ scripts/
│  ├─ prepare-x11.sh
│  ├─ compose.sh
│  ├─ build-limx-ws.sh
│  ├─ bootstrap-isaaclab.sh
│  └─ ...
├─ IsaacLab/                 # git submodule, official Isaac Lab
├─ ros_ws/
│  └─ src/
│     ├─ robot-description/  # git submodule
│     ├─ limxsdk-lowlevel/   # git submodule
│     ├─ robot-visualization/ # git submodule
│     └─ tron1-gazebo-ros2/  # git submodule
├─ leisaac/                  # git submodule
├─ mujoco/
└─ isaac-cache/
```

`IsaacLab/`, `leisaac/`, and the LimX workspace sources under `ros_ws/src/` are tracked as Git submodules. Generated Docker, ROS build, MuJoCo, and cache outputs are ignored.

## 1. Host setup on NixOS

Merge `nixos/configuration-fragment.nix` into your NixOS config and replace `YOUR_USER`.

This fragment intentionally does **not** install `docker-compose` or `mesa-demos` globally:

- use `docker compose`, not the old standalone `docker-compose` binary;
- use `nix shell nixpkgs#mesa-demos -c glxinfo -B` only when a host-side GL check is needed.

After rebuilding:

```bash
sudo nixos-rebuild switch
newgrp docker
```

Check Docker, Compose, and NVIDIA CDI:

```bash
docker compose version
nvidia-smi
nvidia-ctk cdi list || true
docker run --rm --device nvidia.com/gpu=all ubuntu:22.04 nvidia-smi
```

## 2. First-time project setup

```bash
tar -xzf robot-sim-docker.tar.gz
cd robot-sim-docker
git submodule update --init --recursive
cp .env.example .env
```

Edit `.env` so `USER_UID` and `USER_GID` match your host user:

```bash
id -u
id -g
```

Prepare X11 forwarding:

```bash
./scripts/prepare-x11.sh
```

If your compositor or XWayland setup rejects the cookie-only method, retry with local xhost relaxation:

```bash
X11_USE_XHOST=1 ./scripts/prepare-x11.sh
```

Revoke later with:

```bash
./scripts/revoke-x11.sh
```

## 3. ROS 2 Humble + Gazebo container

Build the container:

```bash
./scripts/compose.sh build ros-gazebo
```

Run a basic GUI smoke test:

```bash
./scripts/check-gui.sh
```

Run the ROS 2 talker/listener smoke test inside one container:

```bash
./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/check-ros2-talk-listen.sh
```

Open an interactive shell:

```bash
./scripts/compose.sh run --rm ros-gazebo bash
```

## 4. LimX / Gazebo workspace

Build the LimX workspace inside the ROS/Gazebo container:

```bash
./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/build-limx-ws.sh
```

The LimX source repositories are submodules. The build script keeps its old clone-on-missing behavior, but a fresh checkout should normally use:

```bash
git submodule update --init --recursive ros_ws/src/robot-description ros_ws/src/limxsdk-lowlevel ros_ws/src/robot-visualization ros_ws/src/tron1-gazebo-ros2
```

Patch `empty_world.launch.py` so `use_support=true`:

```bash
./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/patch-empty-world-use-support.sh
```

Launch Gazebo:

```bash
./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/run-gazebo-empty-world.sh
```

Change robot type in `.env` if needed:

```dotenv
ROBOT_TYPE=PF_P441C
```

## 5. Isaac Lab official Docker workflow

This project adopts the official Isaac Lab Docker workflow rather than maintaining a separate hand-written Isaac Lab image.

Prepare the upstream checkout and copy NixOS/LeIsaac overrides into `IsaacLab/docker/`:

```bash
git submodule update --init IsaacLab
./scripts/bootstrap-isaaclab.sh
```

Start the official `ros2` container profile:

```bash
./scripts/start-isaaclab-ros2.sh
```

Enter it:

```bash
./scripts/enter-isaaclab-ros2.sh
```

Stop it:

```bash
./scripts/stop-isaaclab-ros2.sh
```

The override file mounted into Isaac Lab does three things:

1. removes the upstream `deploy.resources.reservations.devices` NVIDIA runtime reservation with Docker Compose `!reset`;
2. adds NixOS-style CDI device selection, `nvidia.com/gpu=all`;
3. bind-mounts this repository's `./leisaac` directory at `/workspace/leisaac`.

## 6. LeIsaac

LeIsaac is a submodule mounted into the Isaac Lab container. Initialize it with:

```bash
git submodule update --init --recursive leisaac
```

`./scripts/bootstrap-leisaac-host.sh` is kept as a fallback for non-submodule worktrees.

Then enter the Isaac Lab ROS2 container and install it into Isaac Lab's Python environment:

```bash
./scripts/enter-isaaclab-ros2.sh
bash /workspace/setup-leisaac-inside-isaaclab.sh
```

The expected host layout after unpacking/cloning is:

```text
leisaac/
└─ source/
   └─ leisaac/
```

The expected asset layout from the original notes is:

```text
leisaac/
└── assets/
    ├── robots/
    │   └── so101_follower.usd
    └── scenes/
        └── table_with_cube/
            ├── scene.usd
            ├── cube/
            └── textures/
```

## 7. MuJoCo

For standalone MuJoCo GUI on NixOS, run it inside the Ubuntu ROS/Gazebo container rather than directly on the host:

```bash
./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/setup-mujoco-standalone.sh
./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/run-mujoco-simulate.sh
```

For Python MuJoCo inside Isaac Lab:

```bash
./scripts/enter-isaaclab-ros2.sh
bash /workspace/setup-mujoco-python-inside-isaaclab.sh
```

## 8. Troubleshooting

### `docker compose` is unavailable

First check:

```bash
docker compose version
```

If the plugin is missing despite `virtualisation.docker.enable = true`, inspect your nixpkgs channel or Docker package override. As a temporary workaround only, you can use a shell:

```bash
nix shell nixpkgs#docker-compose -c docker compose version
```

### NVIDIA CDI is unavailable

Check:

```bash
nvidia-ctk cdi list || true
```

Try regenerating after driver changes:

```bash
sudo systemctl restart nvidia-cdi-refresh.service 2>/dev/null || true
sudo systemctl restart nvidia-container-toolkit-cdi-generator.service 2>/dev/null || true
nvidia-ctk cdi list || true
```

### Isaac Lab official compose still tries `driver: nvidia`

Check the merged config:

```bash
cd IsaacLab
../scripts/isaaclab-container.sh config ros2 \
  --files docker-compose.nixos-cdi.leisaac.patch.yaml \
  --env-files .env.leisaac
```

Confirm that `deploy:` is removed/reset and `devices:` contains `nvidia.com/gpu=all`.

### GUI does not open

Run:

```bash
./scripts/prepare-x11.sh
./scripts/check-gui.sh
```

If that fails under Wayland/XWayland:

```bash
X11_USE_XHOST=1 ./scripts/prepare-x11.sh
./scripts/check-gui.sh
```
