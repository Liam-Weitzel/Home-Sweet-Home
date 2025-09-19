{ config, pkgs, lib, ... }:

{
  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["amd"];

  environment.systemPackages = with pkgs; [
    blender-hip
  ];

  environment.variables = {
    ROC_ENABLE_PRE_VEGA = "1";
  };

  services.lact.enable = true;

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    opengl.extraPackages = with pkgs; [
      # OpenCL support for the older Radeon R300, R400, R500,
      # R600, R700, Evergreen, Northern Islands,
      # Southern Islands (radeon), and Sea Islands (radeon)
      # GPU families
      mesa.opencl
      # NOTE: at some point GPUs in the R600 family and newer
      # may need to replace this with the "rusticl" ICD;
      # and GPUs in the R500-family and older may need to
      # pin the package version or backport Clover
      # - https://www.phoronix.com/news/Mesa-Delete-Clover-Discussion
      # - https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/19385
    ];
  };
}
