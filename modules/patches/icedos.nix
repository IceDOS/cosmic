{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.patches =
    let
      inherit (icedosLib) mkBoolOption;
      inherit (lib) readFile;

      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.patches)
        cosmic-comp
        cosmic-osd
        cosmic-panel
        ;

      inherit (cosmic-comp) disableMonitorsOnLock fixTilingHintClipping fixWakeFromSleep perWindowKeyboardLayout;
      inherit (cosmic-osd) keyboardLayoutOsd;
      inherit (cosmic-panel.autohide) alwaysHide;
    in
    {
      cosmic-comp = {
        disableMonitorsOnLock = mkBoolOption { default = disableMonitorsOnLock; };
        fixTilingHintClipping = mkBoolOption { default = fixTilingHintClipping; };
        fixWakeFromSleep = mkBoolOption { default = fixWakeFromSleep; };
        perWindowKeyboardLayout = mkBoolOption { default = perWindowKeyboardLayout; };
      };

      cosmic-osd.keyboardLayoutOsd = mkBoolOption { default = keyboardLayoutOsd; };
      cosmic-panel.autohide.alwaysHide = mkBoolOption { default = alwaysHide; };
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        { config, lib, ... }:
        let
          inherit (config.icedos.desktop.cosmic.patches) cosmic-comp cosmic-osd cosmic-panel;
          inherit (cosmic-comp) disableMonitorsOnLock fixTilingHintClipping fixWakeFromSleep perWindowKeyboardLayout;
          inherit (cosmic-osd) keyboardLayoutOsd;
          inherit (cosmic-panel.autohide) alwaysHide;
          inherit (lib) optional;

          doCheck = false;
          hasCosmicCompPatch = disableMonitorsOnLock || fixTilingHintClipping || fixWakeFromSleep || perWindowKeyboardLayout;
        in
        {
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
            );
        }
      )
    ];

  meta.name = "patches";
}
