{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.wallpaper =
    let
      inherit (icedosLib)
        mkBoolOption
        mkNumberOption
        mkStrOption
        mkSubmoduleListOption
        ;

      inherit (lib) head readFile;

      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.wallpaper)
        fit
        seconds
        wallpaper
        ;
    in
    {
      fit = mkBoolOption { default = fit; };

      monitors =
        let
          inherit (head (fromTOML (readFile ./monitors.toml)).icedos.desktop.cosmic.wallpaper.monitors)
            name
            ;
        in
        mkSubmoduleListOption { default = [ ]; } {
          name = mkStrOption { default = name; };
          fit = mkBoolOption { default = fit; };
          seconds = mkNumberOption { default = seconds; };
          wallpaper = mkStrOption { default = wallpaper; };
        };

      seconds = mkNumberOption { default = seconds; };
      wallpaper = mkStrOption { default = wallpaper; };
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
        let
          osConfig = config;
        in
        {
          home-manager.sharedModules = [
            (
              { config, ... }:

              let
                inherit (config.lib.cosmic) mkRON;

                inherit (osConfig.icedos) desktop;
                inherit (desktop) cosmic;

                inherit (cosmic.wallpaper)
                  fit
                  monitors
                  seconds
                  ;

                inherit (icedosLib) abortIf;

                inherit (lib)
                  head
                  last
                  length
                  listToAttrs
                  mkIf
                  readFile
                  strings
                  toUpper
                  ;

                inherit (import ../../../lib.nix { inherit lib; }) hexToRgb;

                wallpaperDefault = (fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.wallpaper.wallpaper;
                stylixFollow = (osConfig.stylix.enable or false) && (cosmic.appearance.followStylix or false);
                stylixImagePath = toString (osConfig.stylix.image or "");

                wallpaper =
                  if stylixFollow && cosmic.wallpaper.wallpaper == wallpaperDefault && stylixImagePath != "" then
                    "path:${stylixImagePath}"
                  else
                    cosmic.wallpaper.wallpaper;

                generateWallpaper =
                  source:
                  let
                    inherit (strings) splitString;
                    stringParts = splitString ":" source;

                    type =
                      if
                        (abortIf (
                          length stringParts != 2
                        ) "A cosmic wallpaper setup's wallpaper attribute is misconfigured!")
                      then
                        head stringParts
                      else
                        "";

                    value = last stringParts;
                  in
                  {
                    color = mkRON "enum" {
                      value = [
                        {
                          colors =
                            let
                              color = mkRON "tuple" (hexToRgb value);
                            in
                            [
                              color
                              color
                            ];

                          radius = 180.0;
                        }
                      ];

                      variant = "Gradient";
                    };

                    path = value;
                  }
                  .${type};

                generateWallpaperConfig = monitor: {
                  filter_by_theme = false;
                  filter_method = mkRON "enum" "Linear";
                  output = monitor;
                  rotation_frequency = seconds;
                  sampling_method = mkRON "enum" "Alphanumeric";
                  scaling_mode = mkRON "enum" (if fit then "Stretch" else "Zoom");

                  source =
                    let
                      inherit (strings) splitString;
                      stringParts = splitString ":" wallpaper;

                      type =
                        if
                          (abortIf (
                            length stringParts != 2
                          ) "A cosmic wallpaper setup's wallpaper attribute is misconfigured!")
                        then
                          head stringParts
                        else
                          "";
                    in
                    mkRON "enum" {
                      value = [
                        (generateWallpaper wallpaper)
                      ];

                      variant =
                        let
                          firstChar = builtins.substring 0 1 type;
                          rest = builtins.substring 1 (builtins.stringLength type - 1) type;
                        in
                        (toUpper firstChar) + rest;
                    };
                };

                perScreen = length monitors > 0;
              in
              {
                wayland.desktopManager.cosmic.wallpapers = mkIf (wallpaper != "" && (length monitors) > 0) [
                  (
                    if (!perScreen) then
                      generateWallpaperConfig "all"
                    else
                      listToAttrs (monitor: generateWallpaperConfig monitor) monitors
                  )
                ];
              }
            )
          ];
        }
      )
    ];

  meta.name = "wallpaper";
}
