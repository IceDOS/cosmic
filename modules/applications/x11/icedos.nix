{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.x11 =
    let
      inherit (icedosLib) mkBoolOption mkStrOption;
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
      scaling = mkStrOption { default = scaling; };
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
          inherit (lib) elem mapAttrs;
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

              force = true;
            in
            {
              home.file = {
                ".config/cosmic/com.system76.CosmicComp/v1/descale_xwayland" = {
                  inherit force;

                  text =
                    if
                      (elem scaling [
                        "true"
                        "false"
                      ])
                    then
                      "r#${scaling}"
                    else
                      scaling;
                };

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
            }
          ) users;
        }
      )
    ];

  meta.name = "x11";
}
