{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.patches =
    let
      inherit (icedosLib) mkBoolOption;
      inherit (lib) readFile;

      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.patches)
        cosmic-applets
        cosmic-comp
        cosmic-notifications
        cosmic-osd
        cosmic-panel
        xdg-desktop-portal-cosmic
        ;

      inherit (cosmic-applets) steamGameIconMatcher;

      inherit (cosmic-comp)
        fixTilingHintClipping
        perWindowKeyboardLayout
        ;

      inherit (cosmic-notifications) windowMatchingRoundness;
      inherit (cosmic-osd) keyboardLayoutOsd;
      inherit (cosmic-panel.autohide) alwaysHide;
      inherit (xdg-desktop-portal-cosmic) useGtkFilePicker;
    in
    {
      cosmic-comp = {
        fixTilingHintClipping = mkBoolOption { default = fixTilingHintClipping; };
        perWindowKeyboardLayout = mkBoolOption { default = perWindowKeyboardLayout; };
      };

      cosmic-applets.steamGameIconMatcher = mkBoolOption { default = steamGameIconMatcher; };
      cosmic-notifications.windowMatchingRoundness = mkBoolOption { default = windowMatchingRoundness; };
      cosmic-osd.keyboardLayoutOsd = mkBoolOption { default = keyboardLayoutOsd; };
      cosmic-panel.autohide.alwaysHide = mkBoolOption { default = alwaysHide; };

      xdg-desktop-portal-cosmic = {
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
            cosmic-notifications
            cosmic-osd
            cosmic-panel
            xdg-desktop-portal-cosmic
            ;

          inherit (cosmic-applets) steamGameIconMatcher;
          inherit (cosmic-comp) fixTilingHintClipping perWindowKeyboardLayout;
          inherit (cosmic-notifications) windowMatchingRoundness;
          inherit (cosmic-osd) keyboardLayoutOsd;
          inherit (cosmic-panel.autohide) alwaysHide;
          inherit (xdg-desktop-portal-cosmic) useGtkFilePicker;
          inherit (lib) mkIf optional;

          doCheck = false;
          hasCosmicCompPatch = fixTilingHintClipping || perWindowKeyboardLayout;
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
                      ++ optional fixTilingHintClipping ./cosmic-comp/fix-tiling-hint-clipping.patch
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
              ++ optional windowMatchingRoundness (
                final: prev: {
                  cosmic-notifications = prev.cosmic-notifications.overrideAttrs (oldAttrs: {
                    postPatch = (oldAttrs.postPatch or "") + ''
                      iced_rs="$cargoDepsCopy"/source-git-*/libcosmic-*/src/theme/style/iced.rs
                      substituteInPlace $iced_rs \
                        --replace-fail \
                        'Button::Card => corner_radii.radius_xs.into(),' \
                        'Button::Card => corner_radii.radius_s.into(),'
                    '';

                    doCheck = false;
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
            );
        }
      )
    ];

  meta.name = "patches";
}
