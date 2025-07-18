{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./modules/email.nix
      ./modules/tui-deck.nix
      ./modules/pc.nix
      ./modules/docker.nix
      ./modules/cppinsights.nix
      ./modules/cppman.nix
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl."vm.swappiness" = 10;
  networking.hostName = "liam-w";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set up time zone.
  time.timeZone = "Europe/Warsaw";

  # Automount connected devices
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pl_PL.UTF-8";
    LC_IDENTIFICATION = "pl_PL.UTF-8";
    LC_MEASUREMENT = "pl_PL.UTF-8";
    LC_MONETARY = "pl_PL.UTF-8";
    LC_NAME = "pl_PL.UTF-8";
    LC_NUMERIC = "pl_PL.UTF-8";
    LC_PAPER = "pl_PL.UTF-8";
    LC_TELEPHONE = "pl_PL.UTF-8";
    LC_TIME = "pl_PL.UTF-8";
  };

  users.users.liam-w = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;
  services.getty.autologinUser = "liam-w";
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "libxml2-2.13.8"
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = [];

  environment.systemPackages = with pkgs; [

    #----=[ workflow ]=----#
    neovim
    tmux
    git
    stow
    fzf
    starship
    wget
    curl
    unzip
    unrar
    ripgrep
    fd
    htop
    usbutils
    udiskie
    udisks
    jq
    pstree
    hyperfine
    zip
    diffutils
    lazygit
    irssi

    gtt
    showmethekey
    typioca
    sl
    hoard
    heh
    flamelens
    lazysql
    fastfetch
    dive
    cloc
    bitwise
    bandwhich

    #----=[ AWS ]=----#
    awscli2
    coldsnap

    #----=[ Python ]=----#
    python312
    pyright #lsp only

    #----=[ Java ]=----#
    zulu8
    jdt-language-server #lsp only

    #----=[ C/C++ ]=----#
    gcc
    valgrind
    bear
    gdb
    clang-tools #c/c++ lsp & more

    #----=[ NIX ]=----#
    nixd #nixos lsp only

  ];

  programs.direnv.enable = true;

  #----=[ Fonts ]=----#
  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;
    packages = with pkgs.nerd-fonts; [
      iosevka
      iosevka-term
    ];
  };

  environment.sessionVariables = {
    EDITOR="nvim";
    GCC_COLORS="error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
