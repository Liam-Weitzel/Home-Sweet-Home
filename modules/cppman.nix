# modules/cppman.nix
{ config, lib, pkgs, ... }:

with lib;

{
  options.cppman.enable = mkEnableOption "Enable cppman, the C++ man page viewer";

  config = mkIf config.cppman.enable {
    environment.systemPackages = [
      (pkgs.stdenv.mkDerivation rec {
        pname = "cppman";
        version = "unstable";

        src = pkgs.fetchFromGitHub {
          owner = "aitjcize";
          repo = "cppman";
          rev = "master";
          sha256 = lib.fakeSha256;  # use this first
        };

        buildInputs = [ pkgs.python3 ];

        installPhase = ''
          mkdir -p $out/bin
          cp cppman $out/bin/cppman
          chmod +x $out/bin/cppman
          patchShebangs $out/bin/cppman
        '';

        meta = {
          description = "C++ man page viewer";
          homepage = "https://github.com/aitjcize/cppman";
          license = lib.licenses.gpl3;
        };
      })
    ];
  };
}
