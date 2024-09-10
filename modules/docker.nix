{ config, pkgs, lib, ... }:

{
  users.users.liamw = {
    extraGroups = [ "docker" ];
  };

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  environment.systemPackages = with pkgs; [ docker ];
}
