{ icedosLib, ... }:

{
  options.icedos.desktop.cosmic.brightnessControl.schedules =
    let
      inherit (icedosLib) mkNumberOption mkSubmoduleListOption;
    in
    mkSubmoduleListOption { default = [ ]; } {
      atHour = mkNumberOption { };
      brightness = mkNumberOption { };
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
          inherit (config.icedos.desktop.cosmic.brightnessControl) schedules;
          inherit (config.icedos) users;
          inherit (lib)
            concatStringsSep
            getExe
            mapAttrs
            sort
            ;

          # Sort schedule entries by atHour ascending
          sorted = sort (a: b: a.atHour < b.atHour) schedules;

          # Generate shell case branches from schedule entries
          parsedSchedules = concatStringsSep "\n" (
            lib.imap0 (
              i: entry:
              let
                brightness = toString (entry.brightness / 100.0);
                hour = toString entry.atHour;
                isLast = i == (builtins.length sorted - 1);

                nextHour =
                  if isLast then
                    toString (builtins.elemAt sorted 0).atHour
                  else
                    toString (builtins.elemAt sorted (i + 1)).atHour;
              in
              if isLast then
                # Last entry: covers from its atHour to the first entry's atHour (wrapping midnight)
                ''
                  if [ "$hour" -ge ${hour} ] || [ "$hour" -lt ${nextHour} ]; then
                    echo "${brightness}"
                    return
                  fi''
              else
                ''
                  if [ "$hour" -ge ${hour} ] && [ "$hour" -lt ${nextHour} ]; then
                    echo "${brightness}"
                    return
                  fi''
            ) sorted
          );

          schedulerScript = pkgs.writeShellScriptBin "cosmic-brightness-scheduler" ''
            last_brightness=""

            get_target_brightness() {
              hour=$(${pkgs.coreutils}/bin/date +%H)
              hour=$((10#$hour))
              ${parsedSchedules}
            }

            while true; do
              target=$(get_target_brightness)

              if [ "$target" != "$last_brightness" ]; then
                busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Brightness d "$target" 2>/dev/null &&
                echo "Set brightness to: $target" &&
                last_brightness="$target"
              fi

              sleep 60
            done
          '';
        in
        {
          home-manager.users = mapAttrs (user: _: {
            systemd.user.services.wl-gammarelay-rs = {
              Unit = {
                Description = "wl-gammarelay-rs - Wayland gamma relay daemon";
                After = [
                  "cosmic-session.target"
                  "graphical-session.target"
                ];
                PartOf = "graphical-session.target";
              };

              Install.WantedBy = [ "cosmic-session.target" ];

              Service = {
                ExecStart = "${getExe pkgs.wl-gammarelay-rs} run";
                Restart = "on-failure";
                RestartSec = 3;
              };
            };

            systemd.user.services.cosmic-brightness-scheduler = {
              Unit = {
                Description = "Scheduled brightness control for COSMIC";

                After = [
                  "cosmic-session.target"
                  "graphical-session.target"
                  "wl-gammarelay-rs.service"
                ];

                Requires = [ "wl-gammarelay-rs.service" ];
                PartOf = "graphical-session.target";
              };

              Install.WantedBy = [ "cosmic-session.target" ];

              Service = {
                ExecStart = "${schedulerScript}/bin/cosmic-brightness-scheduler";
                Restart = "on-failure";
                RestartSec = 5;
              };
            };
          }) users;

          nixpkgs.overlays = [
            (final: prev: {
              cosmic-comp = prev.cosmic-comp.overrideAttrs (old: {
                doCheck = false;
                patches = (old.patches or [ ]) ++ [ ./gamma-control.patch ];
              });
            })
          ];
        }
      )
    ];

  meta.name = "brightness-control";
}
