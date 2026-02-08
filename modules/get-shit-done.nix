{ config, pkgs, lib, ... }:

let
  get-shit-done = pkgs.stdenv.mkDerivation rec {
    pname = "get-shit-done";
    version = "1.11.2";

    src = pkgs.fetchFromGitHub {
      owner = "glittercowboy";
      repo = "get-shit-done";
      rev = "v${version}";
      sha256 = "sha256-6Qvir1YXEmGCC2iLd/nB3kxw32HUdKn9Wcbn5KWca8A=";
    };

    nativeBuildInputs = with pkgs; [ nodejs ];

    buildPhase = ''
      # No build step needed - it's a simple Node.js script
    '';

    installPhase = ''
      mkdir -p $out/bin $out/lib/node_modules/get-shit-done

      # Copy all source files
      cp -r * $out/lib/node_modules/get-shit-done/

      # Create executable wrapper
      cat > $out/bin/get-shit-done-cc << EOF
#!/usr/bin/env bash
exec ${pkgs.nodejs}/bin/node $out/lib/node_modules/get-shit-done/bin/install.js "\$@"
EOF
      chmod +x $out/bin/get-shit-done-cc

      # Also create a shorter alias
      ln -s $out/bin/get-shit-done-cc $out/bin/gsd
    '';

    meta = with lib; {
      description = "Meta-prompting and context engineering system for AI code generation";
      homepage = "https://github.com/glittercowboy/get-shit-done";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };
in
{
  environment.systemPackages = [ get-shit-done ];
}