{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.accessibility.magnifier =
    let
      inherit (icedosLib) mkBoolOption mkNumberOption;
      inherit (lib) mkOption readFile types;

      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.accessibility.magnifier)
        mouseZoomShortcuts
        moveZoom
        overlay
        startOnLogin
        zoomPercentage
        ;
    in
    {
      moveZoom = mkOption {
        type = types.enum [
          "Continuously"
          "OnEdge"
          "Centered"
        ];

        default = moveZoom;
      };

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
            ) users;
        }
      )
    ];

  meta.name = "magnifier";
}
