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
          ...
        }:
        let
          inherit (config.icedos.desktop.cosmic.workspaces)
            orientation
            perScreen
            tile
            ;
        in
        {
          home-manager.sharedModules = [
            (
              { config, ... }:
              let
                inherit (config.lib.cosmic) mkRON;
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
            )
          ];
        }
      )
    ];

  meta.name = "workspaces";
}
