{ ... }:

{
  inputs.cosmic-manager = {
    url = "github:HeitorAugustoLN/cosmic-manager";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };

  outputs.nixosModules =
    { inputs, ... }:
    [
      (
        { pkgs, ... }:

        {
          environment.systemPackages = with pkgs; [
            cosmic-ext-applet-caffeine
            cosmic-ext-applet-external-monitor-brightness
            cosmic-ext-tweaks
          ];

          environment.cosmic.excludePackages = with pkgs; [
            cosmic-edit
            cosmic-player
            cosmic-reader
            cosmic-store
            cosmic-term
          ];

          services.desktopManager.cosmic.enable = true;
        }
      )

      (
        {
          config,
          lib,
          ...
        }:

        let
          inherit (lib) mapAttrs;
          inherit (config.icedos) users;
        in

        {
          home-manager.users = mapAttrs (user: _: {
            imports = [
              inputs.cosmic-manager.homeManagerModules.cosmic-manager
            ];

            wayland.desktopManager.cosmic.enable = true;
          }) users;
        }
      )
    ];

  meta = {
    name = "default";

    dependencies = [
      {
        modules = [
          "appearance"
          "cosmic-files"
          "cosmic-screenshot"
          "dock"
          "input"
          "magnifier"
          "mono-sound"
          "panel"
          "power"
          "sound"
          "startup"
          "time"
          "wallpaper"
          "window-management"
          "workspaces"
          "x11"
        ];
      }

      {
        url = "github:icedos/desktop";
      }

      {
        url = "github:icedos/apps";
        modules = [
          "gnome-control-center"
          "walker"
        ];
      }
    ];
  };
}
