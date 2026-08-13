{ config, pkgs, lib, ... }:

{
  # Arc (Xe / Xe2) runs on modesetting + Mesa iris, so unlike nvidia.nix there
  # is no services.xserver.videoDrivers entry to set. hardware.graphics.enable
  # and enable32Bit live in pc.nix since they are vendor-neutral.

  environment.systemPackages = with pkgs; [
    intel-gpu-tools
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver # VAAPI
    vpl-gpu-rt         # oneVPL runtime, needed on Core Ultra
  ];
}
