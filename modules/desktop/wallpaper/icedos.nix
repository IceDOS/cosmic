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

      inherit
        (
          let
            inherit (lib) readFile;
          in
          (fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.wallpaper
        )
        fit
        seconds
        wallpaper
        ;
    in
    {
      fit = mkBoolOption { default = fit; };

      monitors = mkSubmoduleListOption { default = [ ]; } {
        name = mkStrOption { default = ""; };
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
          pkgs,
          ...
        }:
        let
          inherit (config.icedos) users;
          inherit (lib) mapAttrs;
        in
        {
          home-manager.users = mapAttrs (
            user: _:
            let
              inherit (config.home-manager.users.${user}.lib.cosmic) mkRON;

              inherit (config.icedos) desktop;
              inherit (desktop) cosmic;

              inherit (cosmic.wallpaper)
                fit
                monitors
                seconds
                wallpaper
                ;

              inherit (icedosLib) abortIf;

              inherit (lib)
                head
                last
                length
                listToAttrs
                splitString
                strings
                toUpper
                ;

              generateColor =
                color:
                let
                  inherit (lib) readFile;
                  inherit (pkgs) bc runCommand;
                  bcBin = "${bc}/bin/bc";
                in
                splitString "," (
                  readFile "${
                    runCommand "hex-to-rgb-tuple" { } ''
                      function printTuple() {
                        echo "scale=8; $1/255" | ${bcBin}
                      }

                      mkdir -p $out
                      hex="#${color}"

                      r=$(printf "%d" 0x''${hex:1:2})
                      g=$(printf "%d" 0x''${hex:3:2})
                      b=$(printf "%d" 0x''${hex:5:2})

                      echo "$(printTuple $r), $(printTuple $g), $(printTuple $b)" > $out/color
                    ''
                  }/color"
                );

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
                  color = mkRON "tuple" (generateColor value);
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
              wayland.desktopManager.cosmic.wallpapers = [
                (
                  if (!perScreen) then
                    generateWallpaperConfig "all"
                  else
                    listToAttrs (monitor: generateWallpaperConfig monitor) monitors
                )
              ];
            }
          ) users;
        }
      )
    ];

  meta.name = "wallpaper";
}
