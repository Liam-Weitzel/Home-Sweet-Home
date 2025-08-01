{ config, pkgs, lib, ... }:

{
  imports =
    [
      # ./nvidia.nix
      ./firefox.nix
      ./cursor.nix
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

  environment.loginShellInit = lib.mkBefore ''
    [[ "$(tty)" == /dev/tty1 ]] && sway
  '';

  environment.systemPackages = with pkgs; [
    sway
    alacritty
    ueberzugpp
    xfce.thunar
    xfce.thunar-volman
    rofi-wayland
    bemoji
    wl-clipboard
    cliphist
    mako
    libnotify
    slurp
    grim
    imagemagick
    wl-color-picker
    wtype
    wdisplays
    pavucontrol
    bluetuith
    guvcview
    bluez
    bluez-tools
    libinput
    galaxy-buds-client
    xdg-desktop-portal-wlr
    xdg-desktop-portal-gtk
    xdg-desktop-portal
    vesktop
    runelite
    pavucontrol
    libreoffice
    gimp
    wf-recorder #records a screen
    postman
    wev #check what input is being sent to wayland
    google-chrome
    nextcloud-client
    wlprop
    xorg.xmodmap
    pulseaudio
    brightnessctl
    wluma
    playerctl
    ncspot
    imv #light-weight image viewer

    gfn-electron

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

  environment.sessionVariables = {
    #General wayland stuffs
    XDG_SESSION_TYPE="wayland";
    XDG_CURRENT_DESKTOP="sway";
    XDG_SESSION_DESKTOP="sway";
    QT_QPA_PLATFORM="wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION=1;

    _JAVA_AWT_WM_NONREPARENTING=1; #Runelite
  };

  xdg.portal = {
    enable = true;
    config.common.default = "wlr";
    wlr.enable = true;
    wlr.settings.screencast = {
      chooser_type = "simple";
      chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
    };
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
