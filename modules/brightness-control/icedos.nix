{ icedosLib, ... }:

{
  options.icedos.desktop.cosmic.brightnessControl.schedules =
    let
      inherit (icedosLib) mkNumberOption mkStrOption mkSubmoduleListOption;
    in
    mkSubmoduleListOption { default = [ ]; } {
      at = mkStrOption { default = "00:00"; };
      brightness = mkNumberOption { default = 100; };
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
                brightness = toString (entry.brightness / 100.0);
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

          schedulerScript = pkgs.writeShellScriptBin "cosmic-brightness-scheduler" ''
            last_brightness=""

            get_target_brightness() {
              now=$((10#$(${pkgs.coreutils}/bin/date +%H) * 60 + 10#$(${pkgs.coreutils}/bin/date +%M)))
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
