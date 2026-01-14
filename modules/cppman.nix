{ lib, pkgs, ... }:

let
  cppman = pkgs.python3Packages.buildPythonPackage rec {
    pname = "cppman";
    version = "0.6.0";

    src = pkgs.fetchFromGitHub {
      owner = "aitjcize";
      repo = "cppman";
      rev = "master";
      sha256 = "sha256-G9nyhEnB7xGiNN+nEhDI632qKB4Q2dLcjuOyYOAS6XU=";
    };

    pyproject = true;

    nativeBuildInputs = [
      pkgs.python3Packages.setuptools
      pkgs.python3Packages.wheel
      pkgs.python3Packages.distutils
      pkgs.unzip
      pkgs.zip
      pkgs.python3Packages.pip
    ];

    propagatedBuildInputs = with pkgs.python3Packages; [
      beautifulsoup4
      html5lib
      lxml
      soupsieve
      webencodings
    ] ++ [
      pkgs.kodiPackages.typing_extensions
      pkgs.groff
    ];

    doCheck = false;
    dontCheckRuntimeDeps = true;

    postBuild = ''
      unzip dist/${pname}-${version}-py3-none-any.whl -d patched-wheel
      sed -i 's/==[0-9.]*//g' patched-wheel/*.dist-info/METADATA
      (cd patched-wheel && zip -r ../${pname}-${version}-py3-none-any.whl .)  # Use original wheel name here
    '';

    installPhase = ''
      ${pkgs.python3Packages.pip}/bin/pip install --no-deps --prefix=$out dist/${pname}-${version}-py3-none-any.whl
    '';

    meta = with lib; {
      description = "C++ man page viewer";
      homepage = "https://github.com/aitjcize/cppman";
      license = licenses.gpl3;
    };
  };
in {
  environment.systemPackages = [ cppman ];
}
