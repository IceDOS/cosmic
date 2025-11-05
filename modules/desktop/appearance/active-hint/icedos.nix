{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.activeWindowHint.size =
    let
      inherit (icedosLib) mkNumberOption;
      inherit
        (
          let
            inherit (lib) readFile;
          in
          (fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.activeWindowHint
        )
        size
        ;
    in
    mkNumberOption { default = size; };

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
          inherit (cosmic.activeWindowHint) size;
          inherit (lib) mapAttrs;
          force = true;
          text = toString size;
        in
        {
          home-manager.users = mapAttrs (user: _: {
            home.file = {
              ".config/cosmic/com.system76.CosmicTheme.Dark/v1/active_hint" = {
                inherit force text;
              };

              ".config/cosmic/com.system76.CosmicTheme.Dark.Builder/v1/active_hint" = {
                inherit force text;
              };

              ".config/cosmic/com.system76.CosmicTheme.Light/v1/active_hint" = {
                inherit force text;
              };

              ".config/cosmic/com.system76.CosmicTheme.Light.Builder/v1/active_hint" = {
                inherit force text;
              };
            };
          }) users;
        }
      )
    ];

  meta.name = "active-hint";
}
