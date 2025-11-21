{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.x11 =
    let
      inherit (icedosLib) mkBoolOption mkStrOption;
      inherit (lib) readFile mkOption;

      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.x11)
        globalShortcuts
        mouseEvents
        scaling
        ;
    in
    {
      globalShortcuts = mkStrOption { default = globalShortcuts; };
      mouseEvents = mkBoolOption { default = mouseEvents; };
      scaling = mkOption { default = scaling; };
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
          inherit (lib) mapAttrs isBool;
          inherit (config.icedos) desktop users;
        in
        {
          home-manager.users = mapAttrs (
            user: _:
            let
              inherit (desktop.cosmic.x11)
                globalShortcuts
                mouseEvents
                scaling
                ;

              inherit (config.home-manager.users.${user}.lib.cosmic) mkRON;

              force = true;
            in
            {
              home.file = {
                ".config/cosmic/com.system76.CosmicComp/v1/xwayland_eavesdropping" = {
                  inherit force;

                  text = ''
                    (
                        keyboard: ${if globalShortcuts == "None" then "r#None" else globalShortcuts},
                        pointer: ${if mouseEvents then "true" else "false"},
                    )
                  '';
                };
              };

              wayland.desktopManager.cosmic.compositor = {
                descale_xwayland = if (isBool scaling) then scaling else mkRON "raw" scaling;
              };
            }
          ) users;
        }
      )
    ];

  meta.name = "x11";
}
