{ config, pkgs, lib, ... }:

let
  runeliteOverlay = self: super: {
    runelite = super.runelite.overrideAttrs (oldAttrs: {
      postInstall = oldAttrs.postInstall + ''
        substituteInPlace $out/share/applications/Runelite.desktop \
          --replace "Exec=runelite" "Exec=env _JAVA_AWT_WM_NONREPARENTING=1 runelite"
      '';
    });
  };
in
{
  nixpkgs.overlays = [ runeliteOverlay ];

  environment.systemPackages = with pkgs; [
    runelite
  ];
}
