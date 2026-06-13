# NixOS host notes

This project keeps the host small:

- Docker daemon and Docker CLI are configured by NixOS.
- `docker compose` is used; the old standalone `docker-compose` binary is not required for this project.
- `mesa-demos` is not installed globally. Use `nix shell nixpkgs#mesa-demos -c glxinfo -B` when you want a host-side GL check.
- ROS, Gazebo, Isaac Lab, LeIsaac, and MuJoCo live in Ubuntu/NVIDIA containers.

Useful host checks:

```bash
docker compose version
nvidia-smi
nvidia-ctk cdi list || true
docker run --rm --device nvidia.com/gpu=all ubuntu:22.04 nvidia-smi
```

If CDI generation looks stale after a driver update:

```bash
sudo systemctl restart nvidia-cdi-refresh.service 2>/dev/null || true
sudo systemctl restart nvidia-container-toolkit-cdi-generator.service 2>/dev/null || true
nvidia-ctk cdi list || true
```
