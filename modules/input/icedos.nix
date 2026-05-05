{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.input =
    let
      inherit (icedosLib)
        mkBoolOption
        mkEnumOption
        mkIntBetweenOption
        mkNonEmptyStrOption
        mkNumberOption
        mkStrListOption
        mkStrOption
        mkSubmoduleListOption
        ;

      inherit (lib)
        head
        readFile
        ;

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
        alternateCharactersKey = mkEnumOption { default = alternateCharactersKey; } [
          ""
          "caps"
          "lalt"
          "lwin"
          "menu"
          "ralt"
          "rwin"
        ];

        capsLockKey = mkEnumOption { default = capsLockKey; } [
          ""
          "backspace"
          "ctrl_modifier"
          "escape"
          "super"
          "swapescape"
        ];

        composeKey = mkEnumOption { default = composeKey; } [
          ""
          "caps"
          "lwin"
          "menu"
          "prsc"
          "ralt"
          "rctrl"
          "rwin"
          "sclk"
        ];

        keyboardLayouts = mkNonEmptyStrOption { default = keyboardLayouts; };

        numlock = mkEnumOption { default = numlock; } [
          "BootOff"
          "BootOn"
          "LastBoot"
        ];

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

        superKeyAction = mkEnumOption { default = superKeyAction; } [
          "AppLibrary"
          "Disable"
          "Launcher"
          "WorkspaceOverview"
        ];
      };

      mouse = {
        acceleration = mkBoolOption { default = acceleration; };
        mouseSpeed = mkIntBetweenOption { default = mouseSpeed; } 0 100;
        naturalScrolling = mkBoolOption { default = naturalScrolling; };
        primaryButtonRight = mkBoolOption { default = primaryButtonRight; };
        scrollingSpeed = mkIntBetweenOption { default = scrollingSpeed; } 1 100;
      };
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
          home-manager.sharedModules =
            let
              inherit (config.icedos.desktop.cosmic.input) keyboard mouse;

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

              inherit (lib) flatten;
              inherit (import ../../lib.nix { inherit lib; }) mouseSpeedToCosmicSpeed pow2;

              mouseSpeedValue = mouseSpeedToCosmicSpeed mouseSpeed;
              scrollFactorValue = pow2 ((0.1 * scrollingSpeed) - 5.0);
            in
            [
              (
                { config, ... }:
                let
                  inherit (config.lib.cosmic) mkRON;
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
                        numlock_state = mkRON "enum" numlock;
                      };

                      xkb_config = {
                        layout = keyboardLayouts;

                        model = "pc104";
                        rules = "";
                        variant = ",";

                        options = mkRON "optional" "
                        terminate:ctrl_alt_bksp
                        ${
                                                  if alternateCharactersKey != "" then ",lv3:${alternateCharactersKey}_switch" else ""
                                                }
                        ${
                                                  if capsLockKey != "" then ",caps:${capsLockKey}" else ""
                                                }
                        ${if composeKey != "" then ",compose:${composeKey}" else ""}";

                        repeat_delay = repeatDelay;
                        repeat_rate = repeatRate;
                      };
                    };

                    shortcuts = (
                      let
                        superKeyShortcut = {
                          action = superKeyAction;
                          command = "";
                          description = "";
                          keys = [ "Super" ];
                        }
                        // (if (superKeyAction != "Disable") then { variant = "System"; } else { variant = ""; });
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
              )
            ];
        }
      )
    ];

  meta.name = "input";
}
