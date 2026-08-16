{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.appearance =
    let
      inherit (icedosLib)
        mkBoolOption
        mkNumberOption
        mkStrOption
        ;

      inherit (lib) importTOML;

      inherit ((importTOML ./config.toml).icedos.desktop.cosmic.appearance)
        followStylix
        gaps
        gtkTheming
        interfaceDensity
        mode
        roundness
        ;
    in
    {
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
          ...
        }:
        let
          osConfig = config;
          inherit (osConfig.icedos) desktop;
        in
        {
          home-manager.sharedModules = [
            (
              {
                config,
                lib,
                pkgs,
                ...
              }:

              let
                inherit (desktop.cosmic) appearance;

                inherit (appearance)
                  followStylix
                  gtkTheming
                  interfaceDensity
                  roundness
                  ;

                resolved = icedosLib.generateAccent osConfig;

                inherit (config.lib.cosmic) mkRON;

                inherit (lib)
                  elemAt
                  genList
                  optionalAttrs
                  importTOML
                  ;

                inherit (import ../../../lib.nix { inherit icedosLib; }) hexToRgb;

                appearanceDefaults = (importTOML ./config.toml).icedos.desktop.cosmic.appearance;

                stylixColors = osConfig.lib.stylix.colors;

                pickColor = slot: fallback: if followStylix then stylixColors.${slot} else fallback;

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

                active_hint = desktop.windows.activeHintSize;

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
                    polarity = osConfig.stylix.polarity;
                  in
                  if polarity == "either" then "auto" else polarity;

                effectiveMode =
                  if followStylix && appearance.mode == appearanceDefaults.mode then
                    stylixPolarityMapped
                  else
                    appearance.mode;

                isModeAuto = effectiveMode == "auto";
                mode = if isModeAuto then "dark" else effectiveMode;

                accent = generateRgbRon { color = resolved.hexNoHash; };

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

                # text_tint shifts on-accent foregrounds (buttons, selected pill)
                # for contrast: white on dark, black on light (accent_fg rule).
                textTintWhite = generateRgbRon { color = "ffffff"; };
                textTintBlack = generateRgbRon { color = "000000"; };

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
                    dark = generatedTheme // {
                      text_tint = textTintWhite;
                    };
                    light = generatedTheme // {
                      text_tint = textTintBlack;
                    };
                  };

                  toolkit =
                    let
                      stylixIconThemeEnabled = followStylix && osConfig.stylix.icons.enable;

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

                xdg.configFile =
                  let
                    mkFontFile = family: {
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
                  {
                    "cosmic/com.system76.CosmicTheme.Mode/v1/auto_switch" = {
                      text = if isModeAuto then "true" else "false";
                    };
                  }
                  // optionalAttrs followStylix {
                    "cosmic/com.system76.CosmicTk/v1/interface_font" = mkFontFile osConfig.stylix.fonts.sansSerif.name;
                    "cosmic/com.system76.CosmicTk/v1/monospace_font" = mkFontFile osConfig.stylix.fonts.monospace.name;
                  };

                # libcosmic derives accent_button.on from luminance (black on dark
                # accents, e.g. base0E); patch built theme files to force contrast.
                home.activation.icedos-cosmic-accent-on-fix =
                  lib.hm.dag.entryAfter
                    [
                      "buildCosmicTheme"
                    ]
                    ''
                      patch_on_block() {
                        local file="$1"
                        local r="$2"
                        local g="$3"
                        local b="$4"
                        [ -f "$file" ] || return 0
                        ${pkgs.gnused}/bin/sed -i -z \
                          's/    on: (\n        red: [0-9.]\+,\n        green: [0-9.]\+,\n        blue: [0-9.]\+,\n        alpha: [0-9.]\+,\n    ),/    on: (\n        red: '"$r"',\n        green: '"$g"',\n        blue: '"$b"',\n        alpha: 1.0,\n    ),/' \
                          "$file" || true
                      }

                      darkBtn="$HOME/.config/cosmic/com.system76.CosmicTheme.Dark/v1/accent_button"
                      lightBtn="$HOME/.config/cosmic/com.system76.CosmicTheme.Light/v1/accent_button"
                      patch_on_block "$darkBtn"  1.0 1.0 1.0
                      patch_on_block "$lightBtn" 0.0 0.0 0.0
                    '';
              }
            )
          ];
        }
      )
    ];

  meta.name = "appearance";
}
