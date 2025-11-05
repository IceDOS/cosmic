{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.themeMode =
    let
      inherit (icedosLib) mkStrOption;
      inherit
        (
          let
            inherit (lib) readFile;
          in
          (fromTOML (readFile ./config.toml)).icedos.desktop.cosmic
        )
        themeMode
        ;
    in
    mkStrOption { default = themeMode; };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          lib,
          ...
        }:
        let
          inherit (config.icedos) desktop users;
          inherit (desktop) cosmic;
          inherit (cosmic) themeMode;
          inherit (lib) mapAttrs mkIf;
          force = true;
          isAuto = themeMode == "auto";
        in
        {
          home-manager.users = mapAttrs (user: _: {
            home.file = {
              ".config/cosmic/com.system76.CosmicTheme.Mode/v1/auto_switch" = {
                inherit force;
                text = if isAuto then "true" else "false";
              };

              ".config/cosmic/com.system76.CosmicTheme.Mode/v1/is_dark" = mkIf (!isAuto) {
                inherit force;
                text = if (themeMode == "dark") then "true" else "false";
              };
            };
          }) users;
        }
      )
    ];

  meta.name = "theme-mode";
}
