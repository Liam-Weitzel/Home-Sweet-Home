{ config, pkgs, lib, ... }:

{
  environment.variables = {
    XCURSOR_THEME = "Banana";
    XCURSOR_SIZE = "32";
  };

  programs.sway.enable = true;

  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="input", ENV{LIBINPUT_DEVICE_GROUP}=="1", ENV{XCURSOR_THEME}="Banana", ENV{XCURSOR_SIZE}="32"
  '';

  environment.sessionVariables = {
    GDK_SCALE = "1";
    GDK_BACKEND = "wayland";
    XCURSOR_THEME = "Banana";
    XCURSOR_SIZE = "32";
  };

  environment.systemPackages = with pkgs; [ banana-cursor ];
}
