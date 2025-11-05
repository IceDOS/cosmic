{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.interfaceDensity =
    let
      inherit (icedosLib) mkStrOption;
      inherit
        (
          let
            inherit (lib) readFile;
          in
          (fromTOML (readFile ./config.toml)).icedos.desktop.cosmic
        )
        interfaceDensity
        ;
    in
    mkStrOption { default = interfaceDensity; };

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
          inherit (cosmic) interfaceDensity;
          inherit (lib) mapAttrs;

          force = true;
          text = interfaceDensity;
        in
        {
          home-manager.users = mapAttrs (user: _: {
            home.file = {
              ".config/cosmic/com.system76.CosmicTk/v1/header_size" = {
                inherit force text;
              };

              ".config/cosmic/com.system76.CosmicTk/v1/interface_density" = {
                inherit force text;
              };
            };
          }) users;
        }
      )
    ];

  meta.name = "interface-density";
}
