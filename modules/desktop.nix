{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./nvidia.nix
    ];

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  environment.systemPackages = with pkgs; [

    #----=[ workflow ]=----#
    sway
    alacritty
    rofi-wayland
    wl-clipboard
    cliphist
    xfce.thunar
    librewolf #NOTE: Requires MOZ_ENABLE_WAYLAND=1
    mako
    slurp
    grim
    imagemagick
    wl-color-picker
    wdisplays
    pavucontrol
    bluetuith
    guvcview

    #----=[ gaming ]=----#
    vesktop
    runelite #NOTE: Requires _JAVA_AWT_WM_NONREPARENTING=1

    #----=[ goldman ]=----#
    citrix_workspace
    zoom-us
  ];

  services.pipewire = {
    enable = true;                           # Enable PipeWire as the multimedia framework
    alsa.enable = true;                      # Enable ALSA support in PipeWire
    alsa.support32Bit = true;                # Enable 32-bit ALSA support
    pulse.enable = true;                     # Enable PulseAudio support in PipeWire
    jack.enable = true;                      # Enable JACK support in PipeWire
  };

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND=1;
    GCC_COLORS="error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01";
    _JAVA_AWT_WM_NONREPARENTING=1;
  };

  xdg.mime.defaultApplications = {
    "application/pdf" = "librewolf.desktop";
    "text/html"="librewolf.desktop";
    "x-scheme-handler/http"="librewolf.desktop";
    "x-scheme-handler/https"="librewolf.desktop";
    "x-scheme-handler/about"="librewolf.desktop";
    "x-scheme-handler/unknown"="librewolf.desktop";
  };
}