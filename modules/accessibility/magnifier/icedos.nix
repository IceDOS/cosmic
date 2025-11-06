{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.accessibility.magnifier =
    let
      inherit (icedosLib) mkBoolOption mkNumberOption mkStrOption;
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.accessibility.magnifier)
        mouseZoomShortcuts
        moveZoom
        overlay
        startOnLogin
        zoomPercentage
        ;
    in
    {
      moveZoom = mkStrOption { default = moveZoom; };
      mouseZoomShortcuts = mkBoolOption { default = mouseZoomShortcuts; };
      overlay = mkBoolOption { default = overlay; };
      startOnLogin = mkBoolOption { default = startOnLogin; };
      zoomPercentage = mkNumberOption { default = zoomPercentage; };
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

        {
          home-manager.users =
            let
              inherit (config.icedos.desktop) users;
              inherit (icedosLib) abortIf;
              inherit (lib) elem mapAttrs;
              force = true;
            in
            mapAttrs (user: _: {
              home.file =
                let
                  inherit (config.icedos.desktop.cosmic.accessibility.magnifier)
                    mouseZoomShortcuts
                    moveZoom
                    overlay
                    startOnLogin
                    zoomPercentage
                    ;
                in
                {
                  ".config/cosmic/com.system76.CosmicComp/v1/accessibility_zoom" = {
                    inherit force;
                    text = ''
                      (
                          start_on_login: ${if startOnLogin then "true" else "false"},
                          show_overlay: ${if overlay then "true" else "false"},
                          increment: ${
                            if
                              (abortIf (zoomPercentage < 1)
                                "cosmic magnifier zoom percentage has to be bigger than 1, ${toString zoomPercentage} is out of range!"
                              )
                            then
                              toString zoomPercentage
                            else
                              ""
                          },
                          view_moves: ${
                            if
                              (abortIf
                                (
                                  !(elem moveZoom [
                                    "Continuously"
                                    "OnEdge"
                                    "Centered"
                                  ])
                                )
                                ''cosmic move zoom view attribute has to one of Continuously, OnEdge, Centered - "${moveZoom}" is invalid!''
                              )
                            then
                              moveZoom
                            else
                              ""
                          },
                          enable_mouse_zoom_shortcuts: ${if mouseZoomShortcuts then "true" else "false"},
                      )
                    '';
                  };
                };
            }) users;
        }
      )
    ];

  meta.name = "magnifier";
}
