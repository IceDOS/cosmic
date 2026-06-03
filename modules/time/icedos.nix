{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          ...
        }:

        {
          home-manager.sharedModules =
            let
              inherit (config.icedos.desktop.clock)
                date
                firstDayOfTheWeek
                hourFormat24
                seconds
                weekday
                ;
            in
            [
              {
                wayland.desktopManager.cosmic.applets.time.settings = {
                  first_day_of_week =
                    {
                      monday = 0;
                      tuesday = 1;
                      wednesday = 2;
                      thursday = 3;
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
              }
            ];
        }
      )
    ];

  meta.name = "time";
}
