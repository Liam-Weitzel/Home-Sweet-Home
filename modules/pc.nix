{ config, pkgs, lib, ... }:

{
  imports =
    [
      # ./nvidia.nix
      # ./amd.nix
      # ./intel-mac-webcam.nix
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
    nextcloud-client
    xorg.xmodmap
    pulseaudio
    brightnessctl
    playerctl
    ncspot
    gpu-viewer
    rpi-imager
    # ollama # ollama serve # ollama run gemma3:4b # google for when on airplane
    libreoffice

    #VIDEO
    vlc
    mpv

    #REVERSE ENGINEERING
    ghidra
    frida-tools
    wireshark
  ];

  # Run AppImages directly. binfmt registers a handler so ./foo.AppImage works
  # without a wrapper, and pulls in the FUSE libs the AppImage runtime dlopen()s.
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

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
