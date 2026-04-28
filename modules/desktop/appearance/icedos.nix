{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.appearance =
    let
      inherit (icedosLib) mkBoolOption mkNumberOption mkStrOption;
      inherit (lib) mkOption types readFile;

      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.appearance)
        accentBase16Slot
        activeHint
        followStylix
        gaps
        gtkTheming
        interfaceDensity
        mode
        roundness
        ;
    in
    {
      accentBase16Slot = mkOption {
        type = types.enum [
          ""
          "base08"
          "base09"
          "base0A"
          "base0B"
          "base0C"
          "base0D"
          "base0E"
          "base0F"
        ];

        default = accentBase16Slot;

        description = ''
          Which base16 slot cosmic should use for its highlight/accent color.
          Empty string "" inherits icedos.desktop.stylix.accentBase16Slot.
        '';
      };

      activeHint = mkNumberOption { default = activeHint; };
      followStylix = mkBoolOption { default = followStylix; };
      gaps = mkNumberOption { default = gaps; };
      gtkTheming = mkBoolOption { default = gtkTheming; };
      interfaceDensity = mkStrOption { default = interfaceDensity; };
      mode = mkStrOption { default = mode; };
      roundness = mkStrOption { default = roundness; };
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
        let
          osConfig = config;
          inherit (osConfig.icedos) desktop;
        in
        {
          home-manager.sharedModules = [
            (
              { config, ... }:

              let
                inherit (desktop.cosmic) appearance;

                inherit (appearance)
                  activeHint
                  followStylix
                  gtkTheming
                  interfaceDensity
                  roundness
                  ;

                # Accent slot: honor explicit cosmic override, otherwise inherit
                # the global stylix choice so everything matches.
                accentBase16Slot =
                  if appearance.accentBase16Slot != "" then
                    appearance.accentBase16Slot
                  else
                    osConfig.icedos.desktop.stylix.accentBase16Slot or "base0D";

                inherit (config.lib.cosmic) mkRON;
                inherit (icedosLib) generateAccentColor;

                inherit (lib)
                  elemAt
                  genList
                  hasAttr
                  optionalAttrs
                  readFile
                  ;

                inherit (import ../../../lib.nix { inherit lib; }) hexToRgb;

                appearanceDefaults = (fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.appearance;

                stylixEnabled = (osConfig.stylix.enable or false) && followStylix;
                stylixColors = osConfig.lib.stylix.colors or { };

                pickColor = slot: fallback: if stylixEnabled then stylixColors.${slot} else fallback;

                generateRgbRon =
                  {
                    color,
                    alpha ? -1,
                  }:
                  let
                    rgb = hexToRgb color;
                    red = elemAt rgb 0;
                    green = elemAt rgb 1;
                    blue = elemAt rgb 2;
                  in
                  mkRON "optional" (
                    {
                      inherit
                        red
                        green
                        blue
                        ;
                    }
                    // (if (alpha < 0) then { } else { inherit alpha; })
                  );

                generateTupleRon =
                  radiuses:
                  let
                    radius0 = elemAt radiuses 0;
                    radiusXs = elemAt radiuses 1;
                    radiusS = elemAt radiuses 2;
                    radiusM = elemAt radiuses 3;
                    radiusL = elemAt radiuses 4;
                    radiusXl = elemAt radiuses 5;
                    mkRonTuple = radius: mkRON "tuple" (genList (_: radius) 4);
                  in
                  {
                    radius_0 = mkRonTuple radius0;
                    radius_xs = mkRonTuple radiusXs;
                    radius_s = mkRonTuple radiusS;
                    radius_m = mkRonTuple radiusM;
                    radius_l = mkRonTuple radiusL;
                    radius_xl = mkRonTuple radiusXl;
                  };

                force = true;

                active_hint = activeHint;

                gaps = mkRON "tuple" [
                  0
                  appearance.gaps
                ];

                corner_radii =
                  {
                    round = generateTupleRon [
                      0.0
                      4.0
                      8.0
                      16.0
                      32.0
                      160.0
                    ];

                    slightly-round = generateTupleRon (
                      [
                        0.0
                        2.0
                      ]
                      ++ genList (_: 8.0) 4
                    );

                    square = generateTupleRon ([ 0.0 ] ++ genList (_: 2.0) 5);
                  }
                  .${roundness};

                stylixPolarityMapped =
                  let
                    polarity = osConfig.stylix.polarity or "dark";
                  in
                  if polarity == "either" then "auto" else polarity;

                effectiveMode =
                  if stylixEnabled && appearance.mode == appearanceDefaults.mode then
                    stylixPolarityMapped
                  else
                    appearance.mode;

                isModeAuto = effectiveMode == "auto";
                mode = if isModeAuto then "dark" else effectiveMode;

                fallbackAccentHex =
                  let
                    raw = generateAccentColor {
                      inherit (desktop) accentColor;
                      gnomeAccentColor = desktop.gnome.accentColor or "blue";
                      hasGnome = hasAttr "gnome" desktop;
                    };
                  in
                  builtins.substring 1 (builtins.stringLength raw - 1) raw;

                accent =
                  if stylixEnabled then
                    generateRgbRon { color = stylixColors.${accentBase16Slot}; }
                  else
                    generateRgbRon { color = fallbackAccentHex; };

                bg_color = generateRgbRon {
                  color = pickColor "base00" "1d1d20";
                  alpha = 1.0;
                };

                primary_container_bg = generateRgbRon {
                  color = pickColor "base01" "2e2e32";
                  alpha = 1.0;
                };

                secondary_container_bg = generateRgbRon {
                  color = pickColor "base02" "434347";
                  alpha = 1.0;
                };

                text_hint = generateRgbRon { color = pickColor "base04" "c0c0c1"; };

                generatedTheme = {
                  inherit
                    accent
                    active_hint
                    bg_color
                    corner_radii
                    gaps
                    mode
                    primary_container_bg
                    secondary_container_bg
                    text_hint
                    ;
                };
              in
              {
                programs.cosmic-files.settings.desktop = {
                  show_content = false;
                  show_mounted_drives = false;
                  show_trash = false;
                };

                wayland.desktopManager.cosmic.appearance = {
                  theme = {
                    dark = generatedTheme;
                    light = generatedTheme;
                  };

                  toolkit =
                    let
                      stylixIconThemeEnabled = stylixEnabled && (osConfig.stylix.icons.enable or false);

                      iconTheme =
                        if stylixIconThemeEnabled then
                          (if mode == "light" then osConfig.stylix.icons.light else osConfig.stylix.icons.dark)
                        else
                          "Tela-black-dark";
                    in
                    {
                      apply_theme_global = gtkTheming;
                      icon_theme = iconTheme;
                      header_size = mkRON "enum" interfaceDensity;
                    };
                };

                home.file = {
                  ".config/cosmic/com.system76.CosmicTheme.Mode/v1/auto_switch" = {
                    inherit force;
                    text = if isModeAuto then "true" else "false";
                  };
                }
                // (
                  # cosmic-manager's configFile mechanism doesn't force-overwrite
                  # toolkit fonts once a stale value is on disk, so own these two
                  # files directly via home.file with force = true. Format must
                  # match exactly what COSMIC reads back as a RON struct.
                  let
                    mkFontFile = family: {
                      inherit force;
                      text = ''
                        (
                            family: "${family}",
                            stretch: Normal,
                            style: Normal,
                            weight: Normal,
                        )
                      '';
                    };
                  in
                  optionalAttrs stylixEnabled {
                    ".config/cosmic/com.system76.CosmicTk/v1/interface_font" =
                      mkFontFile osConfig.stylix.fonts.sansSerif.name;
                    ".config/cosmic/com.system76.CosmicTk/v1/monospace_font" =
                      mkFontFile osConfig.stylix.fonts.monospace.name;
                  }
                );
              }
            )
          ];
        }
      )
    ];

  meta.name = "appearance";
}
