{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.accessibility =
    let
      inherit (icedosLib) mkBoolOption;
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.accessibility) monoSound;
    in
    {
      monoSound = mkBoolOption { default = monoSound; };
    };
  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          lib,
          ...
        }:

        {
          home-manager.users =
            let
              inherit (config.icedos.desktop) users;
              inherit (lib) mapAttrs;
              force = true;
            in
            mapAttrs (user: _: {
              home.file =
                let
                  inherit (config.icedos.desktop.cosmic.accessibility) monoSound;
                in
                {
                  ".config/cosmic/com.system76.CosmicSettingsDaemon/v1/mono_sound" = {
                    inherit force;
                    text = if monoSound then "true" else "false";
                  };
                };
            }) users;
        }
      )
    ];

  meta.name = "mono-sound";
}
