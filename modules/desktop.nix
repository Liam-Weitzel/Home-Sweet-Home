{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./nvidia.nix
      ./firefox.nix
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

  users.users.liamw.extraGroups = [ "input" ];

  environment.loginShellInit = lib.mkBefore ''
    [[ "$(tty)" == /dev/tty1 ]] && sway
  '';

  environment.systemPackages = with pkgs; [
    sway
    alacritty
    rofi-wayland
    bemoji
    wl-clipboard
    cliphist
    xfce.thunar
    mako
    slurp
    grim
    imagemagick
    wl-color-picker
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
    wf-recorder
    postman
    wev
    google-chrome
    nextcloud-client
    wlprop

    #GAMEDEV
    aseprite
    tiled
    sfxr
    steam
    godot_4

    #VIDEO
    obs-studio
    vlc
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
    # exec_before = "disable_notifications.sh";
    # exec_after = "enable_notifications.sh";
    wlr.settings.screencast = {
      chooser_type = "dmenu";
      chooser_cmd = "${pkgs.rofi-wayland}/bin/rofi -dmenu";
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

  xdg.mime.defaultApplications = {
    "application/pdf" = "librewolf.desktop";
    "text/html"="librewolf.desktop";
    "x-scheme-handler/http"="librewolf.desktop";
    "x-scheme-handler/https"="librewolf.desktop";
    "x-scheme-handler/about"="librewolf.desktop";
    "x-scheme-handler/unknown"="librewolf.desktop";
  };
}
