{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.gaps =
    let
      inherit (icedosLib) mkNumberOption;
      inherit
        (
          let
            inherit (lib) readFile;
          in
          (fromTOML (readFile ./config.toml)).icedos.desktop.cosmic
        )
        gaps
        ;
    in
    mkNumberOption { default = gaps; };

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
          inherit (cosmic) gaps;
          inherit (lib) mapAttrs;
          force = true;
          text = "(0, ${toString gaps})";
        in
        {
          home-manager.users = mapAttrs (user: _: {
            home.file = {
              ".config/cosmic/com.system76.CosmicTheme.Dark/v1/gaps" = {
                inherit force text;
              };

              ".config/cosmic/com.system76.CosmicTheme.Dark.Builder/v1/gaps" = {
                inherit force text;
              };

              ".config/cosmic/com.system76.CosmicTheme.Light/v1/gaps" = {
                inherit force text;
              };

              ".config/cosmic/com.system76.CosmicTheme.Light.Builder/v1/gaps" = {
                inherit force text;
              };
            };
          }) users;
        }
      )
    ];

  meta.name = "gaps";
}
