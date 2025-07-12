{ config, lib, pkgs, ... }:

let
  tui-deck = pkgs.stdenv.mkDerivation {
    pname = "tui-deck";
    version = "0.5.16";

    src = pkgs.fetchurl {
      url = "https://github.com/mebitek/tui-deck/releases/download/0.5.16/tui-deck";
      sha256 = "17dm6wn78lnx4bsf9vb7z2wxfg4qfycqvbx9jc0ncpvqx3p7j30h";
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/tui-deck
      chmod +x $out/bin/tui-deck
    '';
  };
in
{
  options = {};
  config = {
    environment.systemPackages = [
      tui-deck
    ];
  };
}
