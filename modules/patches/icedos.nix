{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.patches =
    let
      inherit (icedosLib) mkBoolOption;
      inherit (lib) readFile;

      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.patches)
        cosmic-applets
        cosmic-comp
        cosmic-osd
        cosmic-panel
        xdg-desktop-portal-cosmic
        ;

      inherit (cosmic-applets) steamGameIconMatcher;
      inherit (cosmic-comp)
        disableMonitorsOnLock
        fixTilingHintClipping
        fixWakeFromSleep
        perWindowKeyboardLayout
        ;
      inherit (cosmic-osd) keyboardLayoutOsd;
      inherit (cosmic-panel.autohide) alwaysHide;
      inherit (xdg-desktop-portal-cosmic) filePickerDefaultSortName useGtkFilePicker;
    in
    {
      cosmic-comp = {
        disableMonitorsOnLock = mkBoolOption { default = disableMonitorsOnLock; };
        fixTilingHintClipping = mkBoolOption { default = fixTilingHintClipping; };
        fixWakeFromSleep = mkBoolOption { default = fixWakeFromSleep; };
        perWindowKeyboardLayout = mkBoolOption { default = perWindowKeyboardLayout; };
      };

      cosmic-applets.steamGameIconMatcher = mkBoolOption { default = steamGameIconMatcher; };
      cosmic-osd.keyboardLayoutOsd = mkBoolOption { default = keyboardLayoutOsd; };
      cosmic-panel.autohide.alwaysHide = mkBoolOption { default = alwaysHide; };

      xdg-desktop-portal-cosmic = {
        filePickerDefaultSortName = mkBoolOption { default = filePickerDefaultSortName; };
        useGtkFilePicker = mkBoolOption { default = useGtkFilePicker; };
      };
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        { config, lib, ... }:
        let
          inherit (config.icedos.desktop.cosmic.patches)
            cosmic-applets
            cosmic-comp
            cosmic-osd
            cosmic-panel
            xdg-desktop-portal-cosmic
            ;

          inherit (cosmic-applets) steamGameIconMatcher;

          inherit (cosmic-comp)
            disableMonitorsOnLock
            fixTilingHintClipping
            fixWakeFromSleep
            perWindowKeyboardLayout
            ;

          inherit (cosmic-osd) keyboardLayoutOsd;
          inherit (cosmic-panel.autohide) alwaysHide;
          inherit (xdg-desktop-portal-cosmic) filePickerDefaultSortName useGtkFilePicker;
          inherit (lib) mkIf optional;

          doCheck = false;
          hasCosmicCompPatch =
            disableMonitorsOnLock || fixTilingHintClipping || fixWakeFromSleep || perWindowKeyboardLayout;
        in
        {
          xdg.portal.config.common = mkIf useGtkFilePicker {
            "org.freedesktop.impl.portal.FileChooser" = "gtk";
          };

          nixpkgs.overlays =
            [ ]
            ++ (
              optional hasCosmicCompPatch (
                final: prev: {
                  cosmic-comp = prev.cosmic-comp.overrideAttrs (old: {
                    inherit doCheck;

                    patches =
                      (old.patches or [ ])
                      ++ optional disableMonitorsOnLock ./cosmic-comp/disable-monitors-on-lock.patch
                      ++ optional fixTilingHintClipping ./cosmic-comp/fix-tiling-hint-clipping.patch
                      ++ optional fixWakeFromSleep ./cosmic-comp/fix-wake-from-sleep.patch
                      ++ optional perWindowKeyboardLayout ./cosmic-comp/per-window-keyboard-layout.patch;
                  });
                }
              )
              ++ optional steamGameIconMatcher (
                final: prev: {
                  cosmic-applets = prev.cosmic-applets.overrideAttrs (old: {
                    inherit doCheck;

                    patches = (old.patches or [ ]) ++ [
                      ./cosmic-applets/steam-game-icon-matcher.patch
                    ];
                  });
                }
              )
              ++ optional keyboardLayoutOsd (
                final: prev: {
                  cosmic-osd = prev.cosmic-osd.overrideAttrs (old: {
                    inherit doCheck;

                    patches = (old.patches or [ ]) ++ [
                      ./cosmic-osd/fix-close-timer-race.patch
                      ./cosmic-osd/keyboard-layout-osd.patch
                    ];
                  });

                  cosmic-settings-daemon = prev.cosmic-settings-daemon.overrideAttrs (old: {
                    inherit doCheck;

                    patches = (old.patches or [ ]) ++ [
                      ./cosmic-settings-daemon/keyboard-layout-osd.patch
                    ];
                  });
                }
              )
              ++ optional alwaysHide (
                final: prev: {
                  cosmic-panel = prev.cosmic-panel.overrideAttrs (oldAttrs: {
                    postPatch = (oldAttrs.postPatch or "") + ''
                      substituteInPlace cosmic-panel-bin/src/space/panel_space.rs \
                        --replace-fail \
                        'let intellihide = self.overlap_notify.is_some();' \
                        'let intellihide = false;'
                    '';

                    doCheck = false;
                  });
                }
              )
              ++ optional filePickerDefaultSortName (
                final: prev: {
                  xdg-desktop-portal-cosmic = prev.xdg-desktop-portal-cosmic.overrideAttrs (oldAttrs: {
                    postPatch = (oldAttrs.postPatch or "") + ''
                      dialog="$cargoDepsCopy"/source-git-*/cosmic-files-*/src/dialog.rs
                      substituteInPlace $dialog \
                        --replace-fail \
                        'tab.sort_name = tab::HeadingOptions::Modified;' \
                        '// sort_name default from Tab::new'
                      substituteInPlace $dialog \
                        --replace-fail \
                        'tab.sort_direction = false;' \
                        '// sort_direction default from Tab::new'
                    '';

                    doCheck = false;
                  });
                }
              )
            );
        }
      )
    ];

  meta.name = "patches";
}
