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
    notmuch
    abook
    mpop
    urlscan
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  services.pcscd.enable = true;
  services.cron = {
    enable = true;
    systemCronJobs = [
      "* * * * * liam-w export XDG_RUNTIME_DIR=/run/user/$(id -u) && /run/current-system/sw/bin/mailsync"
      "* * * * * liam-w /run/current-system/sw/bin/vdirsyncer sync"
    ];
  };
}
