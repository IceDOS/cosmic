{ icedosLib, ... }:

{
  options.icedos.desktop.cosmic.gtkTheming =
    let
      inherit (icedosLib) mkBoolOption;
    in
    mkBoolOption { default = true; };

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
          inherit (config.icedos) users;
          inherit (lib) mapAttrs;

          force = true;
          text = "true";
        in
        {
          home-manager.users = mapAttrs (user: _: {
            home.file = {
              ".config/cosmic/com.system76.CosmicTk/v1/apply_theme_global" = {
                inherit force text;
              };
            };
          }) users;
        }
      )
    ];

  meta.name = "gtk-theming";
}
