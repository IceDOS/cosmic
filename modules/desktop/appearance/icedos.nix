{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.appearance =
    let
      inherit (icedosLib) mkBoolOption mkNumberOption mkStrOption;
      inherit
        (
          let
            inherit (lib) readFile;
          in
          (fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.appearance
        )
        activeHint
        gaps
        gtkTheming
        interfaceDensity
        mode
        roundness
        ;
    in
    {
      activeHint = mkNumberOption { default = activeHint; };
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
          inherit (config.icedos) desktop users;
          inherit (lib) mapAttrs;
        in
        {
          home-manager.users = mapAttrs (
            user: _:
            let
              inherit (desktop) accentColor;
              inherit (desktop.cosmic) appearance;

              inherit (appearance)
                activeHint
                gtkTheming
                interfaceDensity
                roundness
                ;

              inherit (config.home-manager.users.${user}.lib.cosmic) mkRON;
              inherit (lib) elemAt genList;
              inherit (import ../../../lib.nix { inherit lib; }) hexToRgb;

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

              isModeAuto = appearance.mode == "auto";
              mode = if isModeAuto then "dark" else appearance.mode;
              accent = generateRgbRon { color = accentColor; };

              bg_color = generateRgbRon {
                color = "1d1d20";
                alpha = 1.0;
              };

              primary_container_bg = generateRgbRon {
                color = "2e2e32";
                alpha = 1.0;
              };

              secondary_container_bg = generateRgbRon {
                color = "434347";
                alpha = 1.0;
              };

              text_hint = generateRgbRon { color = "c0c0c1"; };

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

                toolkit = {
                  apply_theme_global = gtkTheming;
                  icon_theme = "Tela-black-dark";
                  header_size = mkRON "enum" interfaceDensity;
                };
              };

              home.file.".config/cosmic/com.system76.CosmicTheme.Mode/v1/auto_switch" = {
                inherit force;
                text = if isModeAuto then "true" else "false";
              };
            }
          ) users;
        }
      )
    ];

  meta.name = "appearance";
}
