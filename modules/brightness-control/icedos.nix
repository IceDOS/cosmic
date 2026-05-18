{ icedosLib, ... }:

{
  options.icedos.desktop.cosmic.brightnessControl =
    let
      inherit (icedosLib)
        mkBoolOption
        mkFloatBetweenOption
        mkIntBetweenOption
        mkNumberOption
        mkStrOption
        mkSubmoduleListOption
        ;

      inherit (builtins) readFile;

      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.brightnessControl.transition)
        enable
        step
        interval
        ;
    in
    {
      schedules = mkSubmoduleListOption { default = [ ]; } {
        at = mkStrOption { default = "00:00"; };
        brightness = mkNumberOption { default = 100; };
      };

      transition = {
        enable = mkBoolOption { default = enable; };

        step = mkIntBetweenOption {
          path = "icedos.desktop.cosmic.brightnessControl.transition.step";
          source = ./config.toml;
          default = step;
        } 1 100;

        interval = mkFloatBetweenOption {
          path = "icedos.desktop.cosmic.brightnessControl.transition.interval";
          source = ./config.toml;
          default = interval;
        } 0.05 10.0;
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
          inherit (config.icedos.desktop.cosmic.brightnessControl) schedules transition;

          inherit (lib)
            concatStringsSep
            getExe
            imap0
            sort
            splitString
            toIntBase10
            ;

          parseTime =
            s:
            let
              parts = splitString ":" s;
              h = toIntBase10 (builtins.elemAt parts 0);
              m = toIntBase10 (builtins.elemAt parts 1);
            in
            h * 60 + m;

          sorted = sort (a: b: parseTime a.at < parseTime b.at) schedules;

          parsedSchedules = concatStringsSep "\n" (
            imap0 (
              i: entry:
              let
                # Emitted as integer percent; scheduler steps in percent and
                # formats the 0.0-1.0 fraction at apply time.
                brightness = toString entry.brightness;
                mins = toString (parseTime entry.at);
                isLast = i == (builtins.length sorted - 1);

                nextMins =
                  if isLast then
                    toString (parseTime (builtins.elemAt sorted 0).at)
                  else
                    toString (parseTime (builtins.elemAt sorted (i + 1)).at);
              in
              if isLast then
                # Last entry wraps past midnight: matches if now is at-or-after its time OR before the next.
                ''
                  if [ "$now" -ge ${mins} ] || [ "$now" -lt ${nextMins} ]; then
                    echo "${brightness}"
                    return
                  fi''
              else
                ''
                  if [ "$now" -ge ${mins} ] && [ "$now" -lt ${nextMins} ]; then
                    echo "${brightness}"
                    return
                  fi''
            ) sorted
          );

          schedulerScript =
            let
              bc = "${pkgs.bc}/bin/bc";
              sleep = "${pkgs.coreutils}/bin/sleep";
              date = "${pkgs.coreutils}/bin/date";
              cut = "${pkgs.coreutils}/bin/cut";
            in
            pkgs.writeShellScriptBin "cosmic-brightness-scheduler" ''
              SMOOTH="${if transition.enable then "true" else "false"}"
              STEP=${toString transition.step}
              INTERVAL=${toString transition.interval}

              last_pct=""

              get_target_brightness() {
                now=$((10#$(${date} +%H) * 60 + 10#$(${date} +%M)))
                ${parsedSchedules}
              }

              read_current_pct() {
                raw=$(busctl --user get-property rs.wl-gammarelay / rs.wl.gammarelay Brightness 2>/dev/null | ${cut} -d' ' -f2)
                case "$raw" in
                  "" | *[!0-9.]* ) echo 100 ;;
                  * ) echo "scale=0; ($raw * 100 + 0.5) / 1" | ${bc} 2>/dev/null || echo 100 ;;
                esac
              }

              apply_pct() {
                busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Brightness d "$(printf '%d.%02d' $(( $1 / 100 )) $(( $1 % 100 )))" 2>/dev/null
              }

              transition_to() {
                tgt=$1

                if [ "$SMOOTH" != "true" ] || [ "$STEP" -le 0 ]; then
                  apply_pct "$tgt"
                  last_pct=$tgt
                  return
                fi

                [ -z "$last_pct" ] && last_pct=$(read_current_pct)
                cur=$last_pct

                while [ "$cur" != "$tgt" ]; do
                  if [ "$cur" -lt "$tgt" ]; then
                    cur=$(( cur + STEP )); [ "$cur" -gt "$tgt" ] && cur=$tgt
                  else
                    cur=$(( cur - STEP )); [ "$cur" -lt "$tgt" ] && cur=$tgt
                  fi
                  apply_pct "$cur"
                  [ "$cur" != "$tgt" ] && ${sleep} "$INTERVAL"
                done

                last_pct=$tgt
              }

              while true; do
                target=$(get_target_brightness)

                if [ -n "$target" ] && [ "$target" != "$last_pct" ]; then
                  transition_to "$target"
                  echo "Set brightness to: $last_pct"
                fi

                ${sleep} 60
              done
            '';
        in
        {
          home-manager.sharedModules = [
            {
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
            }
          ];

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
