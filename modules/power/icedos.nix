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
              force = true;
            in
            mapAttrs (user: _: {
              home.file =
                let
                  inherit (users.${user}.idle) disableMonitors suspend;
                in
                {
                  ".config/cosmic/com.system76.CosmicIdle/v1/screen_off_time" = {
                    inherit force;
                    text = if (disableMonitors.enable) then "Some(${toString (disableMonitors.seconds * 1000)})" else "None";
                  };

                  ".config/cosmic/com.system76.CosmicIdle/v1/suspend_on_ac_time" = {
                    inherit force;
                    text = if (suspend.enable) then "Some(${toString (suspend.seconds * 1000)})" else "None";
                  };
                };
            }) users;
        }
      )
    ];

  meta.name = "power";
}
