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
          ...
        }:

        let
          inherit (config.icedos.desktop.cosmic.accessibility) monoSound;
          force = true;
        in
        {
          home-manager.sharedModules = [
            {
              home.file = {
                ".config/cosmic/com.system76.CosmicSettingsDaemon/v1/mono_sound" = {
                  inherit force;
                  text = if monoSound then "true" else "false";
                };
              };
            }
          ];
        }
      )
    ];

  meta.name = "mono-sound";
}
