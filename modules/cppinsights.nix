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

/*

{ config, lib, pkgs, ... }:

let
  llvmSrc = pkgs.fetchgit {
    url = "https://github.com/llvm/llvm-project.git";
    rev = "llvmorg-20.1.8";
    sha256 = "0v0lwf58i96vcwsql3hlgy72z3ncfvqwgyghyn26m2ri8vy83k6a";
  };

  cppinsightsSrc = pkgs.fetchFromGitHub {
    owner = "andreasfertig";
    repo = "cppinsights";
    rev = "a4532a5bf9afba22143f40cc75b9d10b6a927c9a";
    sha256 = "0m882w7ar7dmj7vqmsxsby2awm6w4h67ydagmvrj6wya0a9km833";
  };

  cppinsights = pkgs.stdenv.mkDerivation {
    pname = "cppinsights";
    version = "20.1";

    nativeBuildInputs = with pkgs; [ cmake ninja clang python3 util-linux ];

    dontUnpack = true;
    configurePhase = ":";

    buildPhase = ''
      mkdir -p llvm-src cppinsights-src build

      echo "Copying LLVM source..."
      cp -a ${llvmSrc}/. llvm-src/

      echo "Copying CppInsights source..."
      cp -a ${cppinsightsSrc}/. cppinsights-src/

      echo "Configuring with CMake..."
      cmake -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" \
        -DLLVM_EXTERNAL_PROJECTS=cppinsights \
        -DLLVM_EXTERNAL_CPPINSIGHTS_SOURCE_DIR=cppinsights-src \
        -DLLVM_ENABLE_RTTI=ON \
        -DLLVM_ENABLE_EH=ON \
        -S llvm-src/llvm \
        -B build

      echo "Building with Ninja..."
      ninja -C build -j $NIX_BUILD_CORES -l $NIX_BUILD_CORES -v
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp build/bin/insights $out/bin/
    '';

    meta = with lib; {
      description = "CppInsights - See your C++ code with the compiler’s eyes";
      homepage = "https://github.com/andreasfertig/cppinsights";
      license = licenses.gpl3Plus;
      platforms = platforms.all;
    };
  };
in {
  environment.systemPackages = [ cppinsights ];
}

*/
