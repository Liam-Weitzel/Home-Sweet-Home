{ config, pkgs, lib, ... }:

{
  programs.obs-studio = {
    enable = true;

    plugins = with pkgs.obs-studio-plugins; [
      obs-aitum-multistream
      # Aitum Vertical. Upstream is Aitum/obs-vertical-canvas and nixpkgs
      # follows the repo name, so it is *not* obs-aitum-vertical. Adds the
      # "Vertical" dock: a second 9:16 canvas with its own sources, encoder
      # and stream/record targets, driven independently of the main canvas.
      obs-vertical-canvas
    ];
  };
}
