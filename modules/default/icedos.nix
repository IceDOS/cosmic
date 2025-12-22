{ icedosLib, lib, ... }:

{
  inputs.cosmic-manager = {
    url = "github:HeitorAugustoLN/cosmic-manager";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };

  options.icedos.desktop.cosmic =
    let
      inherit (icedosLib) mkBoolOption mkStrListOption;
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic)
        disableExcludedPackagesWarning
        excludeDefaultPackages
        ;
    in
    {
      disableExcludedPackagesWarning = mkBoolOption { default = disableExcludedPackagesWarning; };
      excludeDefaultPackages = mkStrListOption { default = excludeDefaultPackages; };
    };

  outputs.nixosModules =
    { inputs, ... }:
    [
      (
        {
          config,
          icedosLib,
          pkgs,
          ...
        }:

        let
          inherit (config.icedos.desktop.cosmic) disableExcludedPackagesWarning excludeDefaultPackages;
          inherit (icedosLib) pkgMapper;
        in
        {
          environment.systemPackages = with pkgs; [
            cosmic-ext-applet-caffeine
            cosmic-ext-applet-external-monitor-brightness
            cosmic-ext-applet-privacy-indicator
            cosmic-ext-tweaks
            file-roller
          ];

          environment.cosmic.excludePackages =
            with pkgs;
            [
              cosmic-edit
              cosmic-player
              cosmic-reader
              cosmic-store
              cosmic-term
            ]
            ++ (pkgMapper excludeDefaultPackages);

          services.desktopManager.cosmic = {
            enable = true;
            showExcludedPkgsWarning = (!disableExcludedPackagesWarning);
          };
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
    ];

    optionalDependencies = [
      {
        url = "github:icedos/desktop";
        modules = [ "cosmic-greeter" ];
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
