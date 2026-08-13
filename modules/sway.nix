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
    waybar
    kanshi
  ];

  environment.loginShellInit = lib.mkAfter ''
    [[ "$(tty)" == /dev/tty1 ]] && sway
  '';

  environment.sessionVariables = {
    # Vulkan renderer for every GPU, not just NVIDIA: anv handles Arc fine and
    # this keeps the sway session identical across both machines.
    WLR_RENDERER = "vulkan";

    # General wayland stuffs for sway
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "sway";
    XDG_SESSION_DESKTOP = "sway";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;

    _JAVA_AWT_WM_NONREPARENTING = 1; # Runelite compatibility
  };

  # xdg-desktop-portal-wlr 0.8.3 freezes a screencast permanently the first time
  # PipeWire starves it of buffers: the graph iteration fails and nothing ever
  # restarts it, so the consumer sits on the last frame it received. The trace
  # signature is a single "pipewire: out of buffers" followed by silence.
  # 0.8.4 adds a timer that re-triggers pw_stream_trigger_process at the
  # negotiated frame rate until a buffer frees up.
  # Lives here rather than in nvidia.nix because the bug is generic: any stream
  # that starves once never recovers. NVIDIA merely makes starvation constant,
  # since sway offers it only BLOCK_LINEAR modifiers and detiling those on
  # import is slow enough that the consumer falls behind. Intel imports fast
  # enough to rarely starve, but it is the same latent bug.
  # Drop once nixpkgs ships >= 0.8.4.
  nixpkgs.overlays = [
    (final: prev: {
      xdg-desktop-portal-wlr = prev.xdg-desktop-portal-wlr.overrideAttrs (old: rec {
        version = "0.8.4";
        src = final.fetchFromGitHub {
          owner = "emersion";
          repo = "xdg-desktop-portal-wlr";
          rev = "v${version}";
          hash = "sha256-8Ohgkz13FcG8ddjjgreXkvFD2Q+zUDZnAM4Oh+C9P/s=";
        };
      });
    })
  ];

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
