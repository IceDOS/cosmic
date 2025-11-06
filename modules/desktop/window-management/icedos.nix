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

      snapWindowsToEdges = mkBoolOption { default = snapWindowsToEdges; };
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
          force = true;
        in
        {
          home-manager.users = mapAttrs (user: _: {
            home.file = {
              ".config/cosmic/com.system76.CosmicComp/v1/active_hint" = {
                inherit force;
                text = if activeHint then "true" else "false";
              };

              ".config/cosmic/com.system76.CosmicComp/v1/cursor_follows_focus" = {
                inherit force;
                text = if cursorFollowsFocus then "true" else "false";
              };

              ".config/cosmic/com.system76.CosmicComp/v1/edge_snap_threshold" = {
                inherit force;
                text = if snapWindowsToEdges then "10" else "0";
              };

              ".config/cosmic/com.system76.CosmicComp/v1/focus_follows_cursor" = {
                inherit force;
                text = if followsCursor then "true" else "false";
              };

              ".config/cosmic/com.system76.CosmicComp/v1/focus_follows_cursor_delay" = {
                inherit force;
                text = toString followsCursorDelay;
              };

              ".config/cosmic/com.system76.CosmicTk/v1/show_maximize" = {
                inherit force;
                text = if maximize then "true" else "false";
              };

              ".config/cosmic/com.system76.CosmicTk/v1/show_minimize" = {
                inherit force;
                text = if minimize then "true" else "false";
              };
            };
          }) users;
        }
      )
    ];

  meta.name = "window-management";
}
