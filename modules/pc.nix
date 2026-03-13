{ config, pkgs, lib, ... }:

{
  imports =
    [
      # ./nvidia.nix
      # ./amd.nix
      ./intel-mac-webcam.nix
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

  users.users.liam-w.extraGroups = [ "input" "video" "wireshark" ];

  environment.systemPackages = with pkgs; [
    foot
    xfce.thunar
    xfce.thunar-volman
    bemoji
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
    pavucontrol
    bruno #postman alternative
    google-chrome
    nextcloud-client
    xorg.xmodmap
    pulseaudio
    brightnessctl
    playerctl
    ncspot
    gpu-viewer
    rpi-imager
    dbeaver-bin

    #GAMEDEV
    aseprite
    tiled
    sfxr
    steam
    blender

    #VIDEO
    vlc
    mpv

    #WORK
    gromit-mpx

    #DRONE
    betaflight-configurator

    #REVERSE ENGINEERING
    ghidra
    frida-tools
    wireshark
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
