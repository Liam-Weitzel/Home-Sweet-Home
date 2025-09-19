{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    sway
    rofi
    wdisplays
    wl-clipboard
    cliphist
    mako
    libnotify
    slurp
    grim
    wtype
    xdg-desktop-portal-wlr
    wf-recorder #records a screen
    imv #light-weight image viewer
    wlprop
    wluma
    wev #check what input is being sent to wayland
    wdisplays
  ];

  environment.loginShellInit = lib.mkBefore ''
    [[ "$(tty)" == /dev/tty1 ]] && sway
  '';

  environment.sessionVariables = {
    # General wayland stuffs for sway
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "sway";
    XDG_SESSION_DESKTOP = "sway";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;

    _JAVA_AWT_WM_NONREPARENTING = 1; # Runelite compatibility
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
}
