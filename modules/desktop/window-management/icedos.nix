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
        controls
        focus
        snapWindowsToEdges
        ;
    in
    {
      controls =
        let
          inherit (controls)
            activeHint
            maximize
            minimize
            ;
        in
        {
          activeHint = mkBoolOption { default = activeHint; };
          maximize = mkBoolOption { default = maximize; };
          minimize = mkBoolOption { default = minimize; };
        };

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
          inherit (config.icedos) desktop users;
          inherit (desktop) cosmic;

          inherit (cosmic.windowManagement) controls focus snapWindowsToEdges;

          inherit (controls)
            activeHint
            maximize
            minimize
            ;

          inherit (focus)
            cursorFollowsFocus
            followsCursor
            followsCursorDelay
            ;

          inherit (lib) mapAttrs;
          inherit (pkgs) callPackage;
        in
        {
          environment.systemPackages = [ (callPackage ./cos-cli/package.nix { }) ];

          home-manager.users = mapAttrs (user: _: {
            wayland.desktopManager.cosmic = {
              appearance.toolkit = {
                show_maximize = maximize;
                show_minimize = minimize;
              };

              compositor = {
                active_hint = activeHint;
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
          }) users;
        }
      )
    ];

  meta.name = "window-management";
}
