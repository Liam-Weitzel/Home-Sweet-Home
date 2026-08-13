{ config, pkgs, lib, ... }:

{
  environment.loginShellInit = lib.mkBefore ''
    [[ "$(tty)" == /dev/tty1 ]] && sway --unsupported-gpu
  '';

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  environment.systemPackages = with pkgs; [
    gpustat
  ];

  environment.sessionVariables = {
    # OpenGL Variables
    GBM_BACKEND="nvidia-drm";
    __GL_GSYNC_ALLOWED=0;
    __GL_VRR_ALLOWED=0;
    __GLX_VENDOR_LIBRARY_NAME="nvidia";
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement = {
      enable = false;
      finegrained = false;
    };
    open = false;
    nvidiaSettings = true;
    forceFullCompositionPipeline = true;
  };
}
