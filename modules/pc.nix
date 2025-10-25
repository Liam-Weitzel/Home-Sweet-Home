{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./nvidia.nix
      # ./amd.nix
      ./firefox.nix
      ./cursor.nix
      ./sway.nix
    ];

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      input = {
        General = {
          UserspaceHID = true;
        };
      };
    };
  };

  services.libinput.enable = true;

  users.users.liam-w.extraGroups = [ "input" "video" ];

  environment.systemPackages = with pkgs; [
    alacritty
    ueberzugpp
    xfce.thunar
    xfce.thunar-volman
    bemoji
    cliphist
    imagemagick
    bluetuith
    guvcview
    bluez
    bluez-tools
    libinput
    galaxy-buds-client
    xdg-desktop-portal-gtk
    xdg-desktop-portal
    vesktop
    runelite
    pavucontrol
    libreoffice
    gimp
    postman
    google-chrome
    nextcloud-client
    xorg.xmodmap
    pulseaudio
    brightnessctl
    playerctl
    ncspot
    gfn-electron
    gamescope
    gpu-viewer
    rpi-imager

    #GAMEDEV
    aseprite
    tiled
    sfxr
    steam
    godot_4
    blender

    #VIDEO
    obs-studio
    vlc
    mpv

    #WORK
    citrix_workspace
    zoom-us
    gromit-mpx

    #DRONE
    betaflight-configurator

    #REVERSE ENGINEERING
    ghidra
    frida-tools
  ];

  programs.steam.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    jack.enable = true;
    audio.enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
  };
}
