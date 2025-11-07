{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      (
        { pkgs, ... }:

        {
          environment.systemPackages = with pkgs; [
            cosmic-ext-applet-external-monitor-brightness
            cosmic-ext-tweaks
          ];

          environment.cosmic.excludePackages = with pkgs; [
            cosmic-edit
            cosmic-player
            cosmic-reader
            cosmic-term
          ];

          services.desktopManager.cosmic.enable = true;
        }
      )
    ];

  meta.name = "default";
}
