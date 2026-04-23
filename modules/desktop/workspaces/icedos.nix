{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.workspaces =
    let
      inherit (icedosLib) mkBoolOption;
      inherit (lib) mkOption types;

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
      orientation = mkOption {
        type = types.enum [
          "Horizontal"
          "Vertical"
        ];
        default = orientation;
      };
      perScreen = mkBoolOption { default = perScreen; };
      tile = mkBoolOption { default = tile; };
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          icedosLib,
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
        in
        {
          home-manager.users = mapAttrs (
            user: _:
            let
              inherit (config.home-manager.users.${user}.lib.cosmic) mkRON;
            in
            {
              wayland.desktopManager.cosmic.compositor = {
                autotile = tile;
                workspaces = {
                  workspace_layout = mkRON "enum" orientation;
                  workspace_mode = mkRON "enum" (if perScreen then "OutputBound" else "Global");
                };
              };
            }
          ) users;
        }
      )
    ];

  meta.name = "workspaces";
}
