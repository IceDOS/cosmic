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
        focus
        ;
    in
    {
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

          inherit (cosmic.windowManagement.focus)
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
              ".config/cosmic/com.system76.CosmicComp/v1/cursor_follow_focus" = {
                inherit force;
                text = if cursorFollowsFocus then "true" else "false";
              };

              ".config/cosmic/com.system76.CosmicComp/v1/focus_follows_cursor" = {
                inherit force;
                text = if followsCursor then "true" else "false";
              };

              ".config/cosmic/com.system76.CosmicComp/v1/focus_follows_cursor_delay" = {
                inherit force;
                text = toString followsCursorDelay;
              };
            };
          }) users;
        }
      )
    ];

  meta.name = "window-management";
}
