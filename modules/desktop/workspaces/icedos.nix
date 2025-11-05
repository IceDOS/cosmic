{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.workspaces =
    let
      inherit (icedosLib) mkBoolOption mkStrOption;

      inherit
        (
          let
            inherit (lib) readFile;
          in
          (fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.workspaces
        )
        orientation
        perScreen
        tile
        ;
    in
    {
      orientation = mkStrOption { default = orientation; };
      perScreen = mkBoolOption { default = perScreen; };
      tile = mkBoolOption { default = tile; };
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
        let
          inherit (config.icedos) desktop users;
          inherit (desktop) cosmic;

          inherit (cosmic.workspaces)
            orientation
            perScreen
            tile
            ;

          inherit (lib) mapAttrs;
          force = true;
        in
        {
          home-manager.users = mapAttrs (user: _: {
            home.file = {
              ".config/cosmic/com.system76.CosmicComp/v1/workspaces" = {
                inherit force;
                text = ''
                  (
                      workspace_mode: ${if perScreen then "OutputBound" else "Global"},
                      workspace_layout: ${orientation},
                  )
                '';
              };

              ".config/cosmic/com.system76.CosmicComp/v1/autotile" = {
                inherit force;
                text = if tile then "true" else "false";
              };
            };
          }) users;
        }
      )
    ];

  meta.name = "workspaces";
}
