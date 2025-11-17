{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.input =
    let
      inherit (icedosLib)
        mkBoolOption
        mkNumberOption
        mkStrOption
        mkSubmoduleListOption
        ;

      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.input) keyboard mouse;

      inherit (keyboard)
        alternateCharactersKey
        capsLockKey
        composeKey
        keyboardLayouts
        numlock
        repeatDelay
        repeatRate
        superKeyAction
        ;

      inherit (mouse)
        acceleration
        mouseSpeed
        naturalScrolling
        primaryButtonRight
        scrollingSpeed
        ;
    in
    {
      keyboard = {
        alternateCharactersKey = mkStrOption { default = alternateCharactersKey; };
        capsLockKey = mkStrOption { default = capsLockKey; };
        composeKey = mkStrOption { default = composeKey; };
        keyboardLayouts = mkStrOption { default = keyboardLayouts; };
        numlock = mkStrOption { default = numlock; };
        repeatDelay = mkNumberOption { default = repeatDelay; };
        repeatRate = mkNumberOption { default = repeatRate; };

        shortcuts = mkSubmoduleListOption { default = [ ]; } {
          action = mkStrOption { default = ""; };
          command = mkStrOption { default = ""; };
          description = mkStrOption { default = ""; };
          key = mkStrOption { default = ""; };
          variant = mkStrOption { default = ""; };
        };

        superKeyAction = mkStrOption { default = superKeyAction; };
      };

      mouse = {
        acceleration = mkBoolOption { default = acceleration; };
        mouseSpeed = mkNumberOption { default = mouseSpeed; };
        naturalScrolling = mkBoolOption { default = naturalScrolling; };
        primaryButtonRight = mkBoolOption { default = primaryButtonRight; };
        scrollingSpeed = mkNumberOption { default = scrollingSpeed; };
      };
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          icedosLib,
          lib,
          pkgs,
          ...
        }:

        {
          home-manager.users =
            let
              inherit (config.icedos) desktop users;
              inherit (desktop.cosmic.input) keyboard mouse;

              inherit (keyboard)
                alternateCharactersKey
                capsLockKey
                composeKey
                keyboardLayouts
                numlock
                repeatDelay
                repeatRate
                shortcuts
                superKeyAction
                ;

              inherit (mouse)
                acceleration
                mouseSpeed
                primaryButtonRight
                naturalScrolling
                scrollingSpeed
                ;

              inherit (icedosLib) abortIf;
              inherit (lib) elem mapAttrs;
            in
            mapAttrs (
              user: _:
              let
                inherit (config.home-manager.users.${user}.lib.cosmic) mkRON;
              in
              {
                home.file.".config/cosmic/com.system76.CosmicComp/v1/input_default" = {
                  force = true;

                  text = ''
                    (
                        state: Enabled,
                        acceleration: Some((
                            profile: Some(${if acceleration then "Adaptive" else "Flat"}),
                            speed: ${
                              if
                                (abortIf (
                                  mouseSpeed < 0 || mouseSpeed > 100
                                ) "The cosmic mouse speed has to be set between 0 - 100, ${toString mouseSpeed} is out of range!")
                              then
                                let
                                  slope = 0.014142271248762554;
                                  y = -0.8099999999999998;
                                in
                                "${toString ((slope * mouseSpeed) + y)}"
                              else
                                ""
                            },
                        )),
                        left_handed: Some(${if primaryButtonRight then "true" else "false"}),
                        scroll_config: Some((
                            method: None,
                            natural_scroll: Some(${if naturalScrolling then "true" else "false"}),
                            scroll_button: None,
                            scroll_factor: Some(${
                              let
                                transformScrollingSpeed =
                                  speed:
                                  let
                                    inherit (lib) readFile;
                                    inherit (pkgs) bc runCommand;
                                    bcBin = "${bc}/bin/bc";
                                    speed' = toString speed;
                                  in
                                  if
                                    (abortIf (
                                      speed < 1 || speed > 100
                                    ) "The cosmic scrolling speed has to be set between 1 - 100, ${speed'} is out of range!")
                                  then
                                    readFile "${runCommand "cosmic-scrolling-speed-calculator" { } ''
                                      raw_result=$(echo "
                                        scale=17;
                                        exponent = (0.1 * ${speed'}) - 5;
                                        base_ln = l(2);
                                        y = e(exponent * base_ln);
                                        y
                                      " | ${bcBin} -l)

                                      final_result=$(printf "%.17f" "$raw_result" | sed 's/^\(.*\)\.0*$/\1/')

                                      echo "$final_result" > $out
                                    ''}"
                                  else
                                    "";
                              in
                              "${transformScrollingSpeed scrollingSpeed}"
                            }),
                        )),
                    )
                  '';
                };

                wayland.desktopManager.cosmic = {
                  compositor = {
                    keyboard_config = {
                      numlock_state = mkRON "enum" (
                        if
                          (abortIf (
                            !(elem numlock [
                              "BootOff"
                              "BootOn"
                              "LastBoot"
                            ])
                          ) ''cosmic numlock state has to one of BootOff, BootOn, LastBoot - "${numlock}" is invalid!'')
                        then
                          numlock
                        else
                          ""
                      );
                    };

                    xkb_config = {
                      layout =
                        if
                          (abortIf (
                            keyboardLayouts == ""
                          ) "cosmic keyboard layouts list cannot be empty, please configure one!")
                        then
                          keyboardLayouts
                        else
                          "";

                      model = "pc104";
                      rules = "";
                      variant = ",";

                      options = mkRON "optional" "
                        terminate:ctrl_alt_bksp
                        ${
                                                if
                                                  (abortIf
                                                    (
                                                      !(elem alternateCharactersKey [
                                                        ""
                                                        "caps"
                                                        "lalt"
                                                        "lwin"
                                                        "menu"
                                                        "ralt"
                                                        "rwin"
                                                      ])
                                                    )
                                                    ''cosmic alternate characters key has to one of lalt, ralt, lwin, rwin, menu, caps or "" - "${alternateCharactersKey}" is invalid!''
                                                  )
                                                then
                                                  ",lv3:${alternateCharactersKey}_switch"
                                                else
                                                  ""
                                              }
                        ${
                                                if
                                                  (abortIf
                                                    (
                                                      !(elem capsLockKey [
                                                        ""
                                                        "backspace"
                                                        "ctrl_modifier"
                                                        "escape"
                                                        "super"
                                                        "swapescape"
                                                      ])
                                                    )
                                                    ''cosmic caps lock key has to one of escape, swapescape, backspace, super, ctrl_modifier or "" - "${capsLockKey}" is invalid!''
                                                  )
                                                then
                                                  ",caps:${capsLockKey}"
                                                else
                                                  ""
                                              }
                        ${
                                                if
                                                  (abortIf
                                                    (
                                                      !(elem composeKey [
                                                        ""
                                                        "caps"
                                                        "lwin"
                                                        "menu"
                                                        "prsc"
                                                        "ralt"
                                                        "rctrl"
                                                        "rwin"
                                                        "sclk"
                                                      ])
                                                    )
                                                    ''cosmic compose key has to one of ralt, lwin, rwin, menu, rctrl, caps, sclk, prsc or "" - "${composeKey}" is invalid!''
                                                  )
                                                then
                                                  ",compose:${composeKey}"
                                                else
                                                  ""
                                              }";

                      repeat_delay = repeatDelay;
                      repeat_rate = repeatRate;
                    };
                  };

                  shortcuts = (
                    let
                      superKeyShortcut =
                        if
                          (abortIf
                            (
                              !(elem superKeyAction [
                                "AppLibrary"
                                "Disable"
                                "Launcher"
                                "WorkspaceOverview"
                              ])
                            )
                            ''cosmic super key action has to one of Launcher, WorkspaceOverview, AppLibrary, Disable - "${superKeyAction}" is invalid!''
                          )
                        then
                          {
                            action = superKeyAction;
                            command = "";
                            description = "";
                            key = "Super";
                          }
                          // (if (superKeyAction != "Disable") then { variant = "System"; } else { variant = ""; })
                        else
                          { };
                    in
                    map (
                      shortcut:
                      let
                        inherit (shortcut)
                          command
                          description
                          key
                          variant
                          ;

                        shortcutAction = shortcut.action;
                      in
                      if (variant == "System" && key != "" && shortcutAction != "") then
                        {
                          inherit key;

                          action = mkRON "enum" {
                            inherit variant;

                            value = [
                              (mkRON "enum" shortcutAction)
                            ];
                          };
                        }
                      else if (command != "" && variant != "" && key != "") then
                        {
                          inherit key;

                          action = mkRON "enum" {
                            inherit variant;

                            value = [
                              command
                            ];
                          };

                          description = mkRON "optional" description;
                        }
                      else if (shortcutAction != "" && key != "") then
                        {
                          inherit key;
                          action = mkRON "enum" shortcutAction;
                        }
                      else
                        { }
                    ) (shortcuts ++ [ superKeyShortcut ])
                  );
                };
              }
            ) users;
        }
      )
    ];

  meta.name = "input";
}
