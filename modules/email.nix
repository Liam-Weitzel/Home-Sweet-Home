{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    mutt-wizard
    neomutt
    isync
    msmtp
    pass
    gettext
    gnupg
    pinentry
    cron
    lynx
    notmuch-mutt
    abook
    mpop
    urlscan
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  services.pcscd.enable = true;
}
