{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.input =
    let
      inherit (icedosLib)
        mkBoolOption
        mkNumberOption
        mkStrListOption
        mkStrOption
        mkSubmoduleListOption
        ;

      inherit (lib) head readFile;
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

        shortcuts =
          let
            inherit (head (fromTOML (readFile ./shortcuts.toml)).icedos.desktop.cosmic.input.keyboard.shortcuts)
              action
              command
              description
              keys
              variant
              ;
          in
          mkSubmoduleListOption { default = [ ]; } {
            action = mkStrOption { default = action; };
            command = mkStrOption { default = command; };
            description = mkStrOption { default = description; };
            keys = mkStrListOption { default = keys; };
            variant = mkStrOption { default = variant; };
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
              inherit (lib) elem flatten mapAttrs;
              inherit (import ../../lib.nix { inherit lib; }) mouseSpeedToCosmicSpeed pow2;

              mouseSpeedValue =
                if
                  (abortIf (
                    mouseSpeed < 0 || mouseSpeed > 100
                  ) "The cosmic mouse speed has to be set between 0 - 100, ${toString mouseSpeed} is out of range!")
                then
                  mouseSpeedToCosmicSpeed mouseSpeed
                else
                  0.0;

              scrollFactorValue =
                if
                  (abortIf (scrollingSpeed < 1 || scrollingSpeed > 100)
                    "The cosmic scrolling speed has to be set between 1 - 100, ${toString scrollingSpeed} is out of range!"
                  )
                then
                  pow2 ((0.1 * scrollingSpeed) - 5.0)
                else
                  1.0;
            in
            mapAttrs (
              user: _:
              let
                inherit (config.home-manager.users.${user}.lib.cosmic) mkRON;
              in
              {
                wayland.desktopManager.cosmic = {
                  compositor = {
                    input_default = {
                      state = mkRON "enum" "Enabled";

                      acceleration = mkRON "optional" {
                        profile = mkRON "optional" (mkRON "enum" (if acceleration then "Adaptive" else "Flat"));
                        speed = mkRON "raw" (toString mouseSpeedValue);
                      };

                      left_handed = mkRON "optional" primaryButtonRight;

                      scroll_config = mkRON "optional" {
                        method = {
                          __type = "optional";
                          value = null;
                        };

                        natural_scroll = mkRON "optional" naturalScrolling;

                        scroll_button = {
                          __type = "optional";
                          value = null;
                        };

                        scroll_factor = mkRON "optional" scrollFactorValue;
                      };
                    };

                    keyboard_config = {
                      numlock_state = mkRON "enum" (
                        if
                          (abortIf (
                            !(elem numlock [
                              "BootOff"
                              "BootOn"
                              "LastBoot"
                            ])
                          ) ''cosmic numlock state has to be one of BootOff, BootOn, LastBoot - "${numlock}" is invalid!'')
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
                                                    ''cosmic alternate characters key has to be one of lalt, ralt, lwin, rwin, menu, caps or "" - "${alternateCharactersKey}" is invalid!''
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
                                                    ''cosmic caps lock key has to be one of escape, swapescape, backspace, super, ctrl_modifier or "" - "${capsLockKey}" is invalid!''
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
                                                    ''cosmic compose key has to be one of ralt, lwin, rwin, menu, rctrl, caps, sclk, prsc or "" - "${composeKey}" is invalid!''
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
                            ''cosmic super key action has to be one of Launcher, WorkspaceOverview, AppLibrary, Disable - "${superKeyAction}" is invalid!''
                          )
                        then
                          {
                            action = superKeyAction;
                            command = "";
                            description = "";
                            keys = [ "Super" ];
                          }
                          // (if (superKeyAction != "Disable") then { variant = "System"; } else { variant = ""; })
                        else
                          { };
                    in
                    flatten (
                      map (
                        shortcut:
                        let
                          inherit (shortcut)
                            command
                            description
                            keys
                            variant
                            ;

                          shortcutAction = shortcut.action;

                          generateShortcut =
                            key:
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
                              { };

                          generatedShortcutsFromKeys = map (key: generateShortcut key) keys;
                        in
                        generatedShortcutsFromKeys
                      ) (shortcuts ++ [ superKeyShortcut ])
                    )
                  );
                };
              }
            ) users;
        }
      )
    ];

  meta.name = "input";
}
