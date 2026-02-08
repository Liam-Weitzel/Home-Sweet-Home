{ config, pkgs, lib, ... }:

{
  # Automatically install/update Claude Code during rebuild
  system.userActivationScripts.claude-code = {
    text = ''
      echo "Installing/updating Claude Code to latest version..."
      ${pkgs.nix}/bin/nix profile remove 'claude-code-nix' 2>/dev/null || true
      ${pkgs.nix}/bin/nix profile install github:sadjow/claude-code-nix
      ${pkgs.nix}/bin/nix profile upgrade 'claude-code-nix' 2>/dev/null || true
      echo "Claude Code installation/update complete!"
    '';
    deps = [ ];
  };

  environment.systemPackages = [ pkgs.claude-monitor ];
}