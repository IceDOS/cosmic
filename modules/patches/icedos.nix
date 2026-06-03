{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.patches =
    let
      inherit (icedosLib) mkBoolOption mkNumberOption;
      inherit (lib) readFile;

      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.patches)
        cosmic-applets
        cosmic-comp
        cosmic-notifications
        cosmic-osd
        cosmic-panel
        pop-gtk-theme
        xdg-desktop-portal-cosmic
        ;

      inherit (cosmic-applets)
        boldPanelText
        centerPanelText
        stableClockWidth
        steamGameIconMatcher
        ;

      inherit (cosmic-comp)
        dmemForegroundBooster
        fixTilingHintClipping
        perWindowKeyboardLayout
        ;

      inherit (cosmic-notifications) windowMatchingRoundness;
      inherit (cosmic-osd) keyboardLayoutOsd osdTimeoutMs;
      inherit (cosmic-panel.autohide) alwaysHide;
      inherit (pop-gtk-theme) skipInkscape;
    in
    {
      cosmic-comp = {
        dmemForegroundBooster = mkBoolOption { default = dmemForegroundBooster; };
        fixTilingHintClipping = mkBoolOption { default = fixTilingHintClipping; };
        perWindowKeyboardLayout = mkBoolOption { default = perWindowKeyboardLayout; };
      };

      cosmic-applets = {
        boldPanelText = mkBoolOption { default = boldPanelText; };
        centerPanelText = mkBoolOption { default = centerPanelText; };
        stableClockWidth = mkBoolOption { default = stableClockWidth; };
        steamGameIconMatcher = mkBoolOption { default = steamGameIconMatcher; };
      };
      cosmic-notifications.windowMatchingRoundness = mkBoolOption { default = windowMatchingRoundness; };

      cosmic-osd = {
        keyboardLayoutOsd = mkBoolOption { default = keyboardLayoutOsd; };
        osdTimeoutMs = mkNumberOption { default = osdTimeoutMs; };
      };

      cosmic-panel.autohide.alwaysHide = mkBoolOption { default = alwaysHide; };
      pop-gtk-theme.skipInkscape = mkBoolOption { default = skipInkscape; };
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
            pop-gtk-theme
            ;

          inherit (cosmic-applets)
            boldPanelText
            centerPanelText
            stableClockWidth
            steamGameIconMatcher
            ;

          inherit (cosmic-comp) dmemForegroundBooster fixTilingHintClipping perWindowKeyboardLayout;
          inherit (cosmic-notifications) windowMatchingRoundness;
          inherit (cosmic-osd) keyboardLayoutOsd osdTimeoutMs;
          inherit (cosmic-panel.autohide) alwaysHide;
          inherit (pop-gtk-theme) skipInkscape;

          inherit (lib)
            filter
            getName
            optional
            optionalString
            ;

          doCheck = false;
          hasCosmicCompPatch = dmemForegroundBooster || fixTilingHintClipping || perWindowKeyboardLayout;

          # libcosmic patch shared by cosmic-notifications and cosmic-applets;
          # both vendor libcosmic separately, so the substitution must run in each build.
          libcosmicCardRoundnessPatch = ''
            iced_rs="$cargoDepsCopy"/source-git-*/libcosmic-*/src/theme/style/iced.rs
            substituteInPlace $iced_rs \
              --replace-fail \
              'Button::Card => corner_radii.radius_xs.into(),' \
              'Button::Card => corner_radii.radius_s.into(),'
          '';

          # Bold panel-button text on clock + input-sources to match workspaces' weight.
          # Horizontal clock anchor differs depending on whether stable-clock-width.patch
          # is also applied, so branch on which form is in the tree at postPatch time.
          boldPanelTextPatch = ''
            if grep -q 'self.core.applet.text(visible_str)' cosmic-applet-time/src/window.rs; then
              substituteInPlace cosmic-applet-time/src/window.rs \
                --replace-fail \
                'self.core.applet.text(visible_str)' \
                'self.core.applet.text(visible_str).font(cosmic::font::bold())'
            else
              substituteInPlace cosmic-applet-time/src/window.rs \
                --replace-fail \
                'self.core.applet.text(formatted_date)' \
                'self.core.applet.text(formatted_date).font(cosmic::font::bold())'
            fi

            substituteInPlace cosmic-applet-time/src/window.rs \
              --replace-fail \
              'self.core.applet.text(piece.to_owned()).into()' \
              'self.core.applet.text(piece.to_owned()).font(cosmic::font::bold()).into()'

            substituteInPlace cosmic-applet-time/src/window.rs \
              --replace-fail \
              'self.core.applet.text(p.to_owned()).into()' \
              'self.core.applet.text(p.to_owned()).font(cosmic::font::bold()).into()'

            substituteInPlace cosmic-applet-input-sources/src/lib.rs \
              --replace-fail \
              'let input_source_text = self.core.applet.text(applet_text);' \
              'let input_source_text = self.core.applet.text(applet_text).font(cosmic::font::bold());'
          '';

          centerPanelTextPatch = ''
            if grep -q 'self.core.applet.text(visible_str)' cosmic-applet-time/src/window.rs; then
              substituteInPlace cosmic-applet-time/src/window.rs \
                --replace-fail \
                'self.core.applet.text(visible_str)' \
                'container(column![space::vertical().height(Length::Fixed(2.25)), self.core.applet.text(visible_str)]).height(Length::Fixed((self.core.applet.suggested_size(true).1 + 2 * self.core.applet.suggested_padding(true).1) as f32)).align_y(Alignment::Center)'

              substituteInPlace cosmic-applet-time/src/window.rs \
                --replace-fail \
                '.class(cosmic::theme::Text::Color(Color::TRANSPARENT))' \
                '.class(cosmic::theme::Text::Color(Color::TRANSPARENT)).height(Length::Fixed((self.core.applet.suggested_size(true).1 + 2 * self.core.applet.suggested_padding(true).1) as f32))'
            else
              substituteInPlace cosmic-applet-time/src/window.rs \
                --replace-fail \
                'self.core.applet.text(formatted_date)' \
                'container(column![space::vertical().height(Length::Fixed(2.25)), self.core.applet.text(formatted_date)]).height(Length::Fixed((self.core.applet.suggested_size(true).1 + 2 * self.core.applet.suggested_padding(true).1) as f32)).align_y(Alignment::Center)'
            fi

            substituteInPlace cosmic-applet-workspaces/src/components/app.rs \
              --replace-fail \
              'self.core.applet.text(&w.name).font(cosmic::font::bold())' \
              'container(column![space::vertical().height(Length::Fixed(2.25)), self.core.applet.text(&w.name).font(cosmic::font::bold())]).height(Length::Fixed((self.core.applet.suggested_size(true).1 + 2 * self.core.applet.suggested_padding(true).1) as f32)).align_y(Alignment::Center)'
          '';
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
                      ++ optional dmemForegroundBooster ./cosmic-comp/dmem-foreground-booster.patch
                      ++ optional fixTilingHintClipping ./cosmic-comp/fix-tiling-hint-clipping.patch
                      ++ optional perWindowKeyboardLayout ./cosmic-comp/per-window-keyboard-layout.patch;
                  });
                }
              )
              ++
                optional
                  (
                    boldPanelText
                    || centerPanelText
                    || steamGameIconMatcher
                    || windowMatchingRoundness
                    || stableClockWidth
                  )
                  (
                    final: prev: {
                      cosmic-applets = prev.cosmic-applets.overrideAttrs (old: {
                        inherit doCheck;

                        patches =
                          (old.patches or [ ])
                          ++ optional steamGameIconMatcher ./cosmic-applets/steam-game-icon-matcher.patch
                          ++ optional stableClockWidth ./cosmic-applets/stable-clock-width.patch;

                        postPatch =
                          (old.postPatch or "")
                          + optionalString centerPanelText centerPanelTextPatch
                          + optionalString boldPanelText boldPanelTextPatch
                          + optionalString windowMatchingRoundness libcosmicCardRoundnessPatch;
                      });
                    }
                  )
              ++ optional keyboardLayoutOsd (
                final: prev: {
                  cosmic-osd = prev.cosmic-osd.overrideAttrs (old: {
                    inherit doCheck;

                    patches = (old.patches or [ ]) ++ [
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
              ++ optional (osdTimeoutMs != 3000) (
                final: prev: {
                  cosmic-osd = prev.cosmic-osd.overrideAttrs (old: {
                    inherit doCheck;

                    postPatch = (old.postPatch or "") + ''
                      substituteInPlace src/components/osd_indicator.rs \
                        --replace-fail \
                        'Duration::from_secs(3)' \
                        'Duration::from_millis(${toString osdTimeoutMs})'
                    '';
                  });
                }
              )
              ++ optional windowMatchingRoundness (
                final: prev: {
                  cosmic-notifications = prev.cosmic-notifications.overrideAttrs (oldAttrs: {
                    inherit doCheck;
                    postPatch = (oldAttrs.postPatch or "") + libcosmicCardRoundnessPatch;
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
              ++ optional skipInkscape (
                final: prev: {
                  pop-gtk-theme = prev.pop-gtk-theme.overrideAttrs (old: {
                    nativeBuildInputs = filter (
                      p:
                      let
                        name = getName p;
                      in
                      name != "inkscape" && name != "optipng"
                    ) old.nativeBuildInputs;

                    # Upstream commits pre-rendered PNGs; stubbing render-*.sh drops the inkscape build dep.
                    postPatch = ''
                      patchShebangs .
                      for file in $(find -name 'render-*.sh'); do
                        printf '#!${prev.runtimeShell}\nexit 0\n' > "$file"
                        chmod +x "$file"
                      done
                    '';
                  });
                }
              )
            );
        }
      )
    ];

  meta.name = "patches";
}
