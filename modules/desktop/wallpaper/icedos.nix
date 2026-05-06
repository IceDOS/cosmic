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
        monitors
        seconds
        ;
    in
    {
      fit = mkBoolOption { default = fit; };
      seconds = mkNumberOption { default = seconds; };

      monitors =
        let
          m = head (fromTOML (readFile ./monitors.toml)).icedos.desktop.cosmic.wallpaper.monitors;
        in
        mkSubmoduleListOption { default = monitors; } {
          name = mkStrOption { default = m.name; };
          fit = mkBoolOption { default = m.fit; };
          seconds = mkNumberOption { default = m.seconds; };
          wallpaper = mkStrOption { default = m.wallpaper; };
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
        let
          osConfig = config;
        in
        {
          home-manager.sharedModules = [
            (
              { config, ... }:

              let
                inherit (config.lib.cosmic) mkRON;

                globalWallpaper = osConfig.icedos.desktop.wallpaper;
                cfg = osConfig.icedos.desktop.cosmic.wallpaper;

                inherit (icedosLib) abortIf;

                inherit (lib)
                  filter
                  hasPrefix
                  head
                  last
                  length
                  mkIf
                  strings
                  toUpper
                  ;

                inherit (import ../../../lib.nix { inherit lib; }) hexToRgb;

                # Cosmic stores wallpapers in "type:value" (color:HEX or
                # path:/img). Accept bare path, explicit "path:" prefix, or
                # "color:" prefix from the global; prepend "path:" only when
                # no recognized prefix is present.
                globalAsTypeValue =
                  if globalWallpaper == "" then
                    ""
                  else if hasPrefix "color:" globalWallpaper || hasPrefix "path:" globalWallpaper then
                    globalWallpaper
                  else
                    "path:${globalWallpaper}";

                resolveMonitor = m: {
                  name = m.name;
                  fit = m.fit;
                  seconds = m.seconds;
                  wallpaper = if m.wallpaper != "" then m.wallpaper else globalAsTypeValue;
                };

                perScreen = length cfg.monitors > 0;

                defaultEntry = {
                  name = "all";
                  fit = cfg.fit;
                  seconds = cfg.seconds;
                  wallpaper = globalAsTypeValue;
                };

                entries = if perScreen then map resolveMonitor cfg.monitors else [ defaultEntry ];

                renderable = filter (e: e.wallpaper != "") entries;

                generateSource =
                  src:
                  let
                    inherit (strings) splitString;
                    parts = splitString ":" src;
                    type = head parts;
                    value = last parts;
                  in
                  {
                    color = mkRON "enum" {
                      value = [
                        {
                          colors =
                            let
                              c = mkRON "tuple" (hexToRgb value);
                            in
                            [
                              c
                              c
                            ];

                          radius = 180.0;
                        }
                      ];

                      variant = "Gradient";
                    };

                    path = value;
                  }
                  .${type};

                generateEntry = e: {
                  filter_by_theme = false;
                  filter_method = mkRON "enum" "Linear";
                  output = e.name;
                  rotation_frequency = e.seconds;
                  sampling_method = mkRON "enum" "Alphanumeric";
                  scaling_mode = mkRON "enum" (if e.fit then "Stretch" else "Zoom");

                  source =
                    let
                      inherit (strings) splitString;
                      parts = splitString ":" e.wallpaper;

                      type =
                        if
                          (abortIf (length parts != 2) "A cosmic wallpaper entry's wallpaper attribute is misconfigured!")
                        then
                          head parts
                        else
                          "";

                      firstChar = builtins.substring 0 1 type;
                      rest = builtins.substring 1 (builtins.stringLength type - 1) type;
                    in
                    mkRON "enum" {
                      value = [
                        (generateSource e.wallpaper)
                      ];

                      variant = (toUpper firstChar) + rest;
                    };
                };
              in
              {
                wayland.desktopManager.cosmic.wallpapers = mkIf (renderable != [ ]) (map generateEntry renderable);
              }
            )
          ];
        }
      )
    ];

  meta.name = "wallpaper";
}
