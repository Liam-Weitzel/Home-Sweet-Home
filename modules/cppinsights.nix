{ config, pkgs, ... }:

let
  cppinsightsVersion = "v_20.1";
  cppinsightsUrl = "https://github.com/andreasfertig/cppinsights/releases/download/${cppinsightsVersion}/insights-ubuntu-amd64.tar.gz";

  cppinsightsPackage = pkgs.stdenv.mkDerivation {
    pname = "cppinsights";
    version = cppinsightsVersion;

    src = pkgs.fetchurl {
      url = cppinsightsUrl;
      sha256 = "sha256-wfskdpo5EVKwjslxs8tReYY8j/ZcPcviM26eqhD8H30=";
    };

    unpackPhase = "tar xzf $src";

    installPhase = ''
      mkdir -p $out/bin
      cp insights $out/bin/
    '';

    meta = with pkgs.lib; {
      description = "CppInsights tool";
      homepage = "https://github.com/andreasfertig/cppinsights";
      license = licenses.mit;
    };
  };
in {
  environment.systemPackages = [ cppinsightsPackage ];
}
