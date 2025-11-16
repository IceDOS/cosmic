{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.time =
    let
      inherit (icedosLib) mkBoolOption mkStrOption;
      inherit (lib) readFile;

      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.time)
        date
        firstDayOfTheWeek
        hourFormat24
        seconds
        weekday
        ;
    in
    {
      date = mkBoolOption { default = date; };
      firstDayOfTheWeek = mkStrOption { default = firstDayOfTheWeek; };
      hourFormat24 = mkBoolOption { default = hourFormat24; };
      seconds = mkBoolOption { default = seconds; };
      weekday = mkBoolOption { default = weekday; };
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
                weekday
                ;

              inherit (lib) mapAttrs;
            in
            mapAttrs (user: _: {
              wayland.desktopManager.cosmic.applets.time.settings = {
                first_day_of_week =
                  {
                    monday = 0;
                    friday = 4;
                    saturday = 5;
                    sunday = 6;
                  }
                  .${firstDayOfTheWeek};

                military_time = hourFormat24;
                show_date_in_top_panel = date;
                show_seconds = seconds;
                show_weekday = weekday;
              };
            }) users;
        }
      )
    ];

  meta.name = "time";
}
