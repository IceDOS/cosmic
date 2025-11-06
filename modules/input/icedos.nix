{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.input =
    let
      inherit (icedosLib) mkBoolOption mkNumberOption mkStrOption;
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
        shortcuts
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
        shortcuts = mkStrOption { default = shortcuts; };
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
              force = true;
            in
            mapAttrs (user: _: {
              home.file = {
                ".config/cosmic/com.system76.CosmicComp/v1/keyboard_config" = {
                  inherit force;
                  text = "(numlock_state: ${
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
                  })";
                };

                ".config/cosmic/com.system76.CosmicComp/v1/input_default" = {
                  inherit force;
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

                ".config/cosmic/com.system76.CosmicComp/v1/xkb_config" = {
                  inherit force;
                  text = ''
                    (
                        rules: "",
                        model: "pc104",
                        layout: "${
                          if
                            (abortIf (keyboardLayouts == "") "cosmic keyboard layout cannot be empty, please configure one!")
                          then
                            keyboardLayouts
                          else
                            ""
                        }",
                        variant: ",",
                        options: Some(
                          "terminate:ctrl_alt_bksp
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
                          }
                        "),
                        repeat_delay: ${toString repeatDelay},
                        repeat_rate: ${toString repeatRate},
                    )
                  '';
                };

                ".config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom" = {
                  inherit force;

                  text = ''
                    {
                        (
                            modifiers: [
                                Super,
                            ],
                        ): ${
                          if
                            ((abortIf
                              (
                                !(elem superKeyAction [
                                  "AppLibrary"
                                  "Disable"
                                  "Launcher"
                                  "WorkspaceOverview"
                                ])
                              )
                              ''cosmic super key action has to one of Launcher, WorkspaceOverview, AppLibrary, Disable - "${superKeyAction}" is invalid!''
                            ) && superKeyAction == "Disable")
                          then
                            "Disable"
                          else
                            "System(${superKeyAction})"
                        },
                        ${shortcuts}
                    }
                  '';
                };
              };
            }) users;
        }
      )
    ];

  meta.name = "input";
}
