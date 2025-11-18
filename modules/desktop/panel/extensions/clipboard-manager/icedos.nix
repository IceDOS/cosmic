{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.panel.extensions.clipboardManager =
    let
      inherit (lib) readFile;

      inherit
        ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.panel.extensions.clipboardManager)
        privateMode
        uniqueSession
        ;

      inherit (icedosLib) mkBoolOption;
    in
    {
      privateMode = mkBoolOption { default = privateMode; };
      uniqueSession = mkBoolOption { default = uniqueSession; };
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          lib,
          pkgs,
          ...
        }:

        {
          nixpkgs.overlays = [
            (final: super: {
              cosmic-ext-applet-clipboard-manager = final.callPackage ./package.nix { };
            })
          ];

          environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;

          environment.systemPackages =
            let
              inherit (pkgs) cosmic-ext-applet-clipboard-manager;
            in
            [
              cosmic-ext-applet-clipboard-manager
            ];

          home-manager.users =
            let
              inherit (config.icedos) desktop users;
              inherit (desktop.cosmic.panel.extensions.clipboardManager) privateMode uniqueSession;
              inherit (lib) mapAttrs;
              force = true;
              pluginFolder = ".config/cosmic/io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager/v3";
            in
            mapAttrs (user: _: {
              home.file = {
                "${pluginFolder}/private_mode" = {
                  inherit force;
                  text = if privateMode then "true" else "false";
                };

                "${pluginFolder}/unique_session" = {
                  inherit force;
                  text = if uniqueSession then "true" else "false";
                };
              };
            }) users;
        }
      )
    ];

  meta.name = "clipboard-manager";
}
