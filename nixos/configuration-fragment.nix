# Merge the relevant parts into /etc/nixos/configuration.nix.
# Replace YOUR_USER with your login name.
#
# docker-compose is intentionally not listed in environment.systemPackages:
# modern Docker on nixpkgs exposes Compose as `docker compose` through the Docker CLI plugin.
# mesa-demos is also intentionally not global; use it ad hoc with:
#   nix shell nixpkgs#mesa-demos -c glxinfo -B

{ config, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      features.cdi = true;
      default-address-pools = [
        { base = "172.27.0.0/16"; size = 24; }
      ];
    };
  };

  users.users.YOUR_USER.extraGroups = [ "docker" "video" "render" ];

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    # Isaac Sim 5.1's GUI RTX renderer crashes on RTX 50-series GPUs with
    # the 595 branch. Pin the maintained 580 branch for this workload.
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

  hardware.nvidia-container-toolkit.enable = true;

  environment.systemPackages = with pkgs; [
    git
    xorg.xauth
    xorg.xhost
  ];
}
