{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./nvidia.nix
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl."vm.swappiness" = 10;   # Reduce swappiness to prioritize physical memory over swap
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  networking.hostName = "liamw";
  #networking.wireless.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set up time zone.
  time.timeZone = "Europe/Warsaw";

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
    description = "liamw";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  security.sudo.wheelNeedsPassword = false;
  services.getty.autologinUser = "liamw";
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [

    #----=[ server ]=----#
    neovim #TODO: requires EDITOR="nvim"
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

    #LSPs
    nil #nix os lsp
    clang-tools #c/c++
    jdt-language-server #java lsp only

    #----=[ pc-essential ]=----#
    sway
    alacritty
    rofi-wayland
    wl-clipboard
    cliphist
    xfce.thunar
    librewolf #TODO: check out zen browser instead
    mako
    slurp
    grim
    imagemagick
    wl-color-picker
    wdisplays
    pavucontrol
    bluetuith

    #----=[ pc-gaming ]=----#
    vesktop
    runelite #TODO: Requires _JAVA_AWT_WM_NONREPARENTING=1

    #----=[ pc-goldman ]=----#
    citrix_workspace
    zoom-us
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

  services.pipewire = {
    enable = true;                           # Enable PipeWire as the multimedia framework
    alsa.enable = true;                      # Enable ALSA support in PipeWire
    alsa.support32Bit = true;                # Enable 32-bit ALSA support
    pulse.enable = true;                     # Enable PulseAudio support in PipeWire
    jack.enable = true;                      # Enable JACK support in PipeWire
  };
  
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND=1;
    EDITOR="nvim";
    GCC_COLORS="error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01";
    _JAVA_AWT_WM_NONREPARENTING=1;
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
