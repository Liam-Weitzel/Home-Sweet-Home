{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./modules/desktop.nix
      ./modules/docker.nix
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl."vm.swappiness" = 10;
  networking.hostName = "liamw";

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

  users.users.liamw = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;
  services.getty.autologinUser = "liamw";
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [

    #----=[ workflow ]=----#
    neovim #NOTE: Requires EDITOR="nvim"
    tmux
    git
    stow
    gcc
    fzf
    starship
    wget
    curl
    unzip
    ripgrep
    fd
    htop
    nix-direnv
    direnv
    zulu8 #Java 8
    usbutils
    udiskie
    udisks
    jq
    pstree

    #----=[ LSP's ]=----#
    nil #nixos lsp only
    clang-tools #c/c++ lsp & more
    jdt-language-server #java lsp only
  ];

  #----=[ Fonts ]=----#
  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;
    packages = with pkgs; [ 
      (nerdfonts.override { fonts = [
        "IBMPlexMono"
        "Iosevka"
        "IosevkaTerm"
      ]; })
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
