{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.x11 =
    let
      inherit (icedosLib) mkBoolOption mkStrOption mkUntypedOption;
      inherit (lib) readFile;

      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.x11)
        globalShortcuts
        mouseEvents
        scaling
        ;
    in
    {
      globalShortcuts = mkStrOption { default = globalShortcuts; };
      mouseEvents = mkBoolOption { default = mouseEvents; };
      scaling = mkUntypedOption { default = scaling; };
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
          inherit (lib) isBool;
          inherit (config.icedos.desktop.cosmic.x11)
            globalShortcuts
            mouseEvents
            scaling
            ;
        in
        {
          home-manager.sharedModules = [
            (
              { config, ... }:
              let
                inherit (config.lib.cosmic) mkRON;
                force = true;
              in
              {
                xdg.configFile."cosmic/com.system76.CosmicComp/v1/xwayland_eavesdropping" = {
                  inherit force;

                  text = ''
                    (
                        keyboard: ${if globalShortcuts == "None" then "r#None" else globalShortcuts},
                        pointer: ${if mouseEvents then "true" else "false"},
                    )
                  '';
                };

                wayland.desktopManager.cosmic.compositor = {
                  descale_xwayland = if (isBool scaling) then scaling else mkRON "raw" scaling;
                };
              }
            )
          ];
        }
      )
    ];

  meta.name = "x11";
}
