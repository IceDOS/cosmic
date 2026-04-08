{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.power.lock.disableMonitorsOnLockKeybind =
    let
      inherit (icedosLib) mkBoolOption;
      inherit (lib) readFile;

      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.power.lock)
        disableMonitorsOnLockKeybind
        ;
    in
    mkBoolOption { default = disableMonitorsOnLockKeybind; };

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
          inherit (config.icedos.desktop.cosmic.power.lock) disableMonitorsOnLockKeybind;
          inherit (config.icedos.desktop) users;

          inherit (lib)
            concatStringsSep
            getExe
            getExe'
            mapAttrs
            mkIf
            optional
            ;

          swayidle = getExe pkgs.swayidle;
          wlopm = getExe pkgs.wlopm;
          loginctl = getExe' pkgs.systemd "loginctl";

          mkIdleScript =
            user:
            let
              inherit (users.${user}.idle) disableMonitors lock;

              timeouts = concatStringsSep " " (
                optional lock.enable "timeout ${toString lock.seconds} '${loginctl} lock-session'"
                ++ optional disableMonitors.enable "timeout ${toString disableMonitors.seconds} '${wlopm} --off \"*\"' resume '${wlopm} --on \"*\"'"
              );

              lockEvents = concatStringsSep " " (
                optional disableMonitorsOnLockKeybind "lock 'sleep 0.5 && ${wlopm} --off \"*\"'"
                ++ optional disableMonitorsOnLockKeybind "unlock '${wlopm} --on \"*\"'"
              );
            in
            pkgs.writeShellScriptBin "cosmic-idle" ''
              exec ${swayidle} -w ${timeouts} ${lockEvents}
            '';

          greeterIdleScript = pkgs.writeShellScriptBin "cosmic-greeter-idle" ''
            uid=$(${pkgs.coreutils}/bin/id -u cosmic-greeter)
            export XDG_RUNTIME_DIR="/run/user/$uid"

            for _ in $(seq 1 30); do
              for sock in "$XDG_RUNTIME_DIR"/wayland-*; do
                [ -e "$sock" ] && break 2
              done
              sleep 1
            done

            [ -e "$sock" ] || exit 1
            export WAYLAND_DISPLAY=''$(basename "$sock")
            exec ${swayidle} -w \
              timeout 300 '${wlopm} --off "*"' resume '${wlopm} --on "*"'
          '';
        in
        {
          home-manager.users = mapAttrs (
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
                screen_off_time = mkRON "raw" "None";
                suspend_on_ac_time = suspendSeconds;
                suspend_on_battery_time = suspendSeconds;
              };

              systemd.user.services.cosmic-idle =
                mkIf (users.${user}.idle.lock.enable || disableMonitors.enable)
                  {
                    Unit = {
                      Description = "Idle manager (swayidle) for COSMIC session";
                      After = [
                        "cosmic-session.target"
                        "graphical-session.target"
                      ];
                      PartOf = "graphical-session.target";
                    };

                    Install.WantedBy = [ "cosmic-session.target" ];

                    Service = {
                      ExecStart = "${mkIdleScript user}/bin/cosmic-idle";
                      Restart = "on-failure";
                      RestartSec = 3;
                    };
                  };
            }
          ) users;

          systemd.services.cosmic-greeter-idle = {
            bindsTo = [ "cosmic-greeter.service" ];
            after = [ "cosmic-greeter.service" ];
            wantedBy = [ "cosmic-greeter.service" ];

            serviceConfig = {
              Type = "simple";
              User = "cosmic-greeter";
              ExecStart = "${greeterIdleScript}/bin/cosmic-greeter-idle";
              Restart = "on-failure";
              RestartSec = 3;
            };
          };
        }
      )
    ];

  meta.name = "power";
}
