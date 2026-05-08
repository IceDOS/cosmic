{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.windowManagement =
    let
      inherit (icedosLib) mkBoolOption mkNumberOption;

      inherit
        (
          let
            inherit (lib) readFile;
          in
          (fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.windowManagement
        )
        cli
        focus
        snapWindowsToEdges
        ;
    in
    {
      cli = mkBoolOption { default = cli; };

      focus =
        let
          inherit (focus)
            cursorFollowsFocus
            followsCursor
            followsCursorDelay
            ;
        in
        {
          cursorFollowsFocus = mkBoolOption { default = cursorFollowsFocus; };
          followsCursor = mkBoolOption { default = followsCursor; };
          followsCursorDelay = mkNumberOption { default = followsCursorDelay; };
        };

      snapWindowsToEdges =
        let
          inherit (snapWindowsToEdges) enable threshold;
        in
        {
          enable = mkBoolOption { default = enable; };
          threshold = mkNumberOption { default = threshold; };
        };
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          inherit (config.icedos) desktop;
          inherit (desktop) windows;

          inherit (desktop.cosmic.windowManagement)
            cli
            focus
            snapWindowsToEdges
            ;

          inherit (focus)
            cursorFollowsFocus
            followsCursor
            followsCursorDelay
            ;

          inherit (lib) mkIf;
          inherit (pkgs) callPackage;
        in
        {
          environment.systemPackages = mkIf cli [ (callPackage ./cos-cli/package.nix { }) ];

          home-manager.sharedModules = [
            {
              wayland.desktopManager.cosmic = {
                appearance.toolkit = {
                  show_maximize = windows.maximizeButton;
                  show_minimize = windows.minimizeButton;
                };

                compositor = {
                  active_hint = windows.activeHint;
                  cursor_follows_focus = cursorFollowsFocus;

                  edge_snap_threshold =
                    let
                      inherit (snapWindowsToEdges) enable threshold;
                    in
                    if enable then threshold else 0;

                  focus_follows_cursor = followsCursor;
                  focus_follows_cursor_delay = followsCursorDelay;
                };
              };
            }
          ];
        }
      )
    ];

  meta.name = "window-management";
}
