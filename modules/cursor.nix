{ config, pkgs, lib, ... }:

{
  environment.variables = {
    XCURSOR_THEME = "Maple";
    XCURSOR_SIZE = "64";
  };

  programs.sway.enable = true;

  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="input", ENV{LIBINPUT_DEVICE_GROUP}=="1", ENV{XCURSOR_THEME}="Maple", ENV{XCURSOR_SIZE}="64"
  '';

  environment.sessionVariables = {
    GDK_SCALE = "1";
    GDK_BACKEND = "wayland";
    XCURSOR_THEME = "Maple";
    XCURSOR_SIZE = "64";
  };

  environment.systemPackages = with pkgs; [ maplestory-cursor ];
}
