{ config, pkgs, lib, ... }:

{
  environment.loginShellInit = lib.mkAfter ''
    [[ "$(tty)" == /dev/tty1 ]] && sway --unsupported-gpu
  '';

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  environment.systemPackages = with pkgs; [
    gpustat
  ];

  environment.sessionVariables = {
    WLR_RENDERER="vulkan";

    # OpenGL Variables
    GBM_BACKEND="nvidia-drm";
    __GL_GSYNC_ALLOWED=0;
    __GL_VRR_ALLOWED=0;
    __GLX_VENDOR_LIBRARY_NAME="nvidia";

    # Turn off hardware accelleration
    # XWAYLAND_NO_GLAMOR=1;
  };

  hardware = {
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;
      powerManagement = {
        enable = false;
        finegrained = false;
      };
      open = false;
      nvidiaSettings = true;
      forceFullCompositionPipeline = true;
    };
  };
}
