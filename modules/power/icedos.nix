{ ... }:

{
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
                inherit (users.${user}.idle) disableMonitors suspend;
                suspendSeconds = mkRON "raw" (
                  if (suspend.enable) then "Some(${toString (suspend.seconds * 1000)})" else "None"
                );
              in
              {
                wayland.desktopManager.cosmic.idle = {
                  screen_off_time = mkRON "raw" (
                    if (disableMonitors.enable) then "Some(${toString (disableMonitors.seconds * 1000)})" else "None"
                  );

                  suspend_on_ac_time = suspendSeconds;
                  suspend_on_battery_time = suspendSeconds;
                };
              }
            ) users;
        }
      )
    ];

  meta.name = "power";
}
