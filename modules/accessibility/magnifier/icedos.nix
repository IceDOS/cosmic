{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.accessibility.magnifier =
    let
      inherit (icedosLib) mkBoolOption mkEnumOption mkNumberOption;
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
      moveZoom =
        mkEnumOption
          {
            path = "icedos.desktop.cosmic.accessibility.magnifier.moveZoom";
            source = ./config.toml;
            default = moveZoom;
          }
          [
            "Continuously"
            "OnEdge"
            "Centered"
          ];

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
          ...
        }:

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
          home-manager.sharedModules = [
            (
              { config, ... }:
              let
                inherit (config.lib.cosmic) mkRON;
              in
              {
                wayland.desktopManager.cosmic.compositor.accessibility_zoom = {
                  enable_mouse_zoom_shortcuts = mouseZoomShortcuts;
                  increment = zoomPercentage;
                  view_moves = mkRON "enum" moveZoom;
                  show_overlay = overlay;
                  start_on_login = startOnLogin;
                };
              }
            )
          ];
        }
      )
    ];

  meta.name = "magnifier";
}
