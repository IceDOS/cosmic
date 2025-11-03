{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.roundness =
    let
      inherit (icedosLib) mkStrOption;
      inherit
        (
          let
            inherit (lib) readFile;
          in
          (fromTOML (readFile ./config.toml)).icedos.desktop.cosmic
        )
        roundness
        ;
    in
    mkStrOption { default = roundness; };

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
          inherit (cosmic) roundness;
          inherit (lib) mapAttrs;

          force = true;
          text =
            {
              round = ''
                (
                    radius_0: (0.0, 0.0, 0.0, 0.0),
                    radius_xs: (4.0, 4.0, 4.0, 4.0),
                    radius_s: (8.0, 8.0, 8.0, 8.0),
                    radius_m: (16.0, 16.0, 16.0, 16.0),
                    radius_l: (32.0, 32.0, 32.0, 32.0),
                    radius_xl: (160.0, 160.0, 160.0, 160.0),
                )
              '';

              slightly-round = ''
                (
                    radius_0: (0.0, 0.0, 0.0, 0.0),
                    radius_xs: (2.0, 2.0, 2.0, 2.0),
                    radius_s: (8.0, 8.0, 8.0, 8.0),
                    radius_m: (8.0, 8.0, 8.0, 8.0),
                    radius_l: (8.0, 8.0, 8.0, 8.0),
                    radius_xl: (8.0, 8.0, 8.0, 8.0),
                )
              '';

              square = ''
                (
                    radius_0: (0.0, 0.0, 0.0, 0.0),
                    radius_xs: (2.0, 2.0, 2.0, 2.0),
                    radius_s: (2.0, 2.0, 2.0, 2.0),
                    radius_m: (2.0, 2.0, 2.0, 2.0),
                    radius_l: (2.0, 2.0, 2.0, 2.0),
                    radius_xl: (2.0, 2.0, 2.0, 2.0),
                )
              '';
            }
            .${roundness};
        in
        {
          home-manager.users = mapAttrs (user: _: {
            home.file = {
              ".config/cosmic/com.system76.CosmicTheme.Dark/v1/corner_radii" = {
                inherit force text;
              };

              ".config/cosmic/com.system76.CosmicTheme.Dark.Builder/v1/corner_radii" = {
                inherit force text;
              };

              ".config/cosmic/com.system76.CosmicTheme.Light/v1/corner_radii" = {
                inherit force text;
              };

              ".config/cosmic/com.system76.CosmicTheme.Light.Builder/v1/corner_radii" = {
                inherit force text;
              };
            };
          }) users;
        }
      )
    ];

  meta.name = "roundness";
}
