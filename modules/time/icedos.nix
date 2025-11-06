{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.time =
    let
      inherit (icedosLib) mkBoolOption mkStrOption;
      inherit (lib) readFile;

      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.time) date firstDayOfTheWeek hourFormat24 seconds;
    in
    {
      date = mkBoolOption { default = date; };
      firstDayOfTheWeek = mkStrOption { default = firstDayOfTheWeek; };
      hourFormat24 = mkBoolOption { default = hourFormat24; };
      seconds = mkBoolOption { default = seconds; };
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
              inherit (config.icedos) desktop users;
              inherit (desktop.cosmic.time)
                date
                firstDayOfTheWeek
                hourFormat24
                seconds
                ;
              inherit (lib) mapAttrs;
              force = true;
            in
            mapAttrs (user: _: {
              home.file = {
                ".config/cosmic/com.system76.CosmicAppletTime/v1/first_day_of_week" = {
                  inherit force;

                  text =
                    {
                      monday = "0";
                      friday = "4";
                      saturday = "5";
                      sunday = "6";
                    }
                    .${firstDayOfTheWeek};
                };

                ".config/cosmic/com.system76.CosmicAppletTime/v1/military_time" = {
                  inherit force;
                  text = if hourFormat24 then "true" else "false";
                };

                ".config/cosmic/com.system76.CosmicAppletTime/v1/show_date_in_top_panel" = {
                  inherit force;
                  text = if date then "true" else "false";
                };

                ".config/cosmic/com.system76.CosmicAppletTime/v1/show_seconds" = {
                  inherit force;
                  text = if seconds then "true" else "false";
                };
              };
            }) users;
        }
      )
    ];

  meta.name = "time";
}
