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
          lib,
          pkgs,
          ...
        }:

        let
          inherit (config.icedos.desktop.cosmic)
            disableExcludedPackagesWarning
            dock
            excludeDefaultPackages
            panel
            ;

          allPlugins =
            dock.plugins.center
            ++ dock.plugins.left
            ++ dock.plugins.right
            ++ panel.plugins.center
            ++ panel.plugins.left
            ++ panel.plugins.right;

          checkIfPluginsExists = plugin: elem plugin allPlugins;

          inherit (icedosLib) genUserDefaults pkgMapper;
          inherit (lib) elem optional;
        in
        {
          icedos.desktop.cosmic.users = genUserDefaults {
            users = config.icedos.users;
          };

          environment.systemPackages =
            with pkgs;
            [
              cosmic-ext-tweaks
              file-roller
            ]
            ++ optional (checkIfPluginsExists "dev.DBrox.CosmicPrivacyIndicator") pkgs.cosmic-ext-applet-privacy-indicator
            ++ optional (checkIfPluginsExists "io.github.cosmic_utils.cosmic-ext-applet-external-monitor-brightness") pkgs.cosmic-ext-applet-external-monitor-brightness
            ++ optional (checkIfPluginsExists "net.tropicbliss.CosmicExtAppletCaffeine") pkgs.cosmic-ext-applet-caffeine;

          environment.cosmic.excludePackages =
            with pkgs;
            [
              cosmic-edit
              cosmic-player
              cosmic-reader
              cosmic-store
              cosmic-term
            ]
            ++ (pkgMapper pkgs excludeDefaultPackages);

          services.desktopManager.cosmic = {
            enable = true;
            showExcludedPkgsWarning = (!disableExcludedPackagesWarning);
          };

          # Restore the polkit SUID helper removed in nixpkgs#473068 (polkit 126→127).
          # cosmic-osd's authentication agent still forks the SUID binary and does not
          # support the new socket-activated IPC service yet (pop-os/cosmic-osd#169).
          # Remove this once cosmic-osd gains socket support.
          security.wrappers.polkit-agent-helper-1 = {
            setuid = true;
            owner = "root";
            group = "root";
            source = "${pkgs.polkit.out}/lib/polkit-1/polkit-agent-helper-1";
          };
        }
      )

      {
        home-manager.sharedModules = [
          {
            imports = [
              inputs.cosmic-manager.homeManagerModules.cosmic-manager
            ];

            wayland.desktopManager.cosmic.enable = true;
          }
        ];
      }
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
          "patches"
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
