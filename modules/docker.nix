{ config, pkgs, lib, ... }:

{
  users.users.liam-w.extraGroups = [ "docker" ];

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  environment.systemPackages = with pkgs; [ docker ];
}
