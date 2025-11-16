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
              inherit (lib) mapAttrs;
            in
            mapAttrs (
              user: _:
              let
                inherit (config.home-manager.users.${user}.lib.cosmic) mkRON;

                inherit (config.icedos.desktop.cosmic.accessibility.magnifier)
                  mouseZoomShortcuts
                  moveZoom
                  overlay
                  startOnLogin
                  zoomPercentage
                  ;

                inherit (icedosLib) abortIf;
                inherit (lib) elem;
              in
              {
                wayland.desktopManager.cosmic.compositor.accessibility_zoom = {
                  enable_mouse_zoom_shortcuts = mouseZoomShortcuts;
                  increment = zoomPercentage;

                  view_moves =
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
                      mkRON "enum" moveZoom
                    else
                      "";

                  show_overlay = overlay;
                  start_on_login = startOnLogin;
                };
              }
            ) users;
        }
      )
    ];

  meta.name = "magnifier";
}
