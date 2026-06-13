# Codex prompt for this repository

あなたはこのリポジトリの作業を引き継ぐCodexです。作業ディレクトリは、このファイルを含む `robot-sim-docker/` のルートです。

## 背景

目的は、NixOSホスト上で、以下の環境をDockerコンテナとして自然に再現することです。

- ROS 2 Humble + Gazebo Classic + LimX workspace は `ros-gazebo` コンテナに閉じ込める。
- Isaac Lab / Isaac Sim は、手書きDockerfileではなく、公式Isaac Labリポジトリの `docker/container.py` と `ros2` profile を使う。
- LeIsaacはホストの `./leisaac` を Isaac Lab コンテナの `/workspace/leisaac` にbind mountして入れる。
- MuJoCo standalone GUIは、NixOSホストで直接実行せず、Ubuntuベースの `ros-gazebo` コンテナ内で動かす。
- NixOSホストにはROS/Conda/Gazebo/Isaacを入れない。ホストはDocker、NVIDIA driver、NVIDIA Container Toolkit/CDI、X11補助だけにする。

## 重要な方針

1. `docker-compose` 単体パッケージは追加しない。`docker compose` を使う。
2. `mesa-demos` はグローバルインストールしない。必要時だけ `nix shell nixpkgs#mesa-demos -c glxinfo -B` を使う。
3. NixOS + NVIDIAは、まず CDI 方式、つまり `nvidia.com/gpu=all` を使う。
4. Isaac Lab公式Docker composeは upstream の `deploy.resources.reservations.devices: driver: nvidia` を持つことがある。NixOS CDIではこれが邪魔になる場合があるため、`overrides/isaaclab-nixos-cdi.leisaac.patch.yaml` では Docker Compose `!reset` で `deploy` を消し、`devices: ["nvidia.com/gpu=all"]` を追加している。この挙動を必ず検証する。
5. 既存方針に反してROSやGazeboをNixOSグローバル環境へ移さない。
6. ユーザーの作業ディレクトリや既存チェックアウトを破壊しない。既存ファイルを変更する場合は理由をコメントか報告に残す。

## 最初に実行する確認

```bash
pwd
ls -la
cp -n .env.example .env
bash -n scripts/*.sh
docker compose version
./scripts/compose.sh config
```

NVIDIA環境ではさらに:

```bash
nvidia-smi
nvidia-ctk cdi list || true
docker run --rm --device nvidia.com/gpu=all ubuntu:22.04 nvidia-smi
```

GUI環境では:

```bash
./scripts/prepare-x11.sh
```

## 優先タスク

### 1. Compose / Dockerfileの検証

- `./scripts/compose.sh config` が通るようにする。
- `compose.nvidia-cdi.yml` の `devices: ["nvidia.com/gpu=all"]` が現在のDocker Composeで有効か確認する。
- もし現在のDocker ComposeでCDI device指定の構文が違う場合は、NixOS CDIの実動作を優先して修正する。
- `containers/ros-gazebo/Dockerfile` のapt package名を検証し、存在しない必須パッケージでbuildが落ちないようにする。任意パッケージはoptional loopへ移す。

### 2. ROS/Gazeboコンテナの確認

可能なら以下を実行して、失敗箇所を修正する。

```bash
./scripts/compose.sh build ros-gazebo
./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/check-ros2-talk-listen.sh
./scripts/check-gui.sh
```

LimX workspaceはネットワークアクセスが必要なので、実行できる環境なら:

```bash
./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/build-limx-ws.sh
./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/patch-empty-world-use-support.sh
```

### 3. Isaac Lab公式Docker workflowの確認

ネットワークアクセスがある場合:

```bash
./scripts/bootstrap-isaaclab.sh
cd IsaacLab
./docker/container.py config ros2 \
  --files docker-compose.nixos-cdi.leisaac.patch.yaml \
  --env-files .env.leisaac
```

確認ポイント:

- service名が `isaac-lab-ros2` のままか。
- merged configで `deploy` が消えているか、少なくともNixOS CDIと競合しないか。
- `devices` に `nvidia.com/gpu=all` が入っているか。
- `./leisaac` が `/workspace/leisaac` にmountされるか。
- `./scripts/setup-leisaac-inside-isaaclab.sh` が `/workspace/setup-leisaac-inside-isaaclab.sh` にread-only mountされるか。

必要なら `overrides/isaaclab-nixos-cdi.leisaac.patch.yaml` と `scripts/bootstrap-isaaclab.sh` を直す。

### 4. LeIsaac / MuJoCoの確認

LeIsaac:

```bash
./scripts/bootstrap-leisaac-host.sh
./scripts/start-isaaclab-ros2.sh
./scripts/enter-isaaclab-ros2.sh
bash /workspace/setup-leisaac-inside-isaaclab.sh
```

MuJoCo standalone:

```bash
./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/setup-mujoco-standalone.sh
./scripts/compose.sh run --rm ros-gazebo /opt/robot-sim/scripts/run-mujoco-simulate.sh
```

MuJoCo Python in Isaac Lab:

```bash
./scripts/enter-isaaclab-ros2.sh
bash /workspace/setup-mujoco-python-inside-isaaclab.sh
```

## 変更時のルール

- できるだけ小さな差分で直す。
- READMEと実際のスクリプトのコマンドがズレたら、必ずREADMEも直す。
- ホストに何かをグローバルインストールする提案を追加する場合は、その必要性を明記する。特に `docker-compose` と `mesa-demos` は原則追加しない。
- upstream Isaac Labのファイルを直接編集し続ける設計にしない。必要な差分は `overrides/` と `scripts/bootstrap-isaaclab.sh` から再適用できる形にする。
- buildやdownloadに時間がかかる場合でも、少なくとも `bash -n`, `docker compose config`, `container.py config` までは確認する。

## 最終報告に含めること

1. 実行したコマンド。
2. 成功した確認項目。
3. 失敗した確認項目と原因の推定。
4. 変更したファイル一覧。
5. ユーザーが次に実行すべき最短コマンド列。
