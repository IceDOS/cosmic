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
          inherit (config.icedos) desktop users;
          inherit (desktop) cosmic;

          inherit (cosmic.wallpaper)
            fit
            monitors
            seconds
            wallpaper
            ;

          inherit (icedosLib) abortIf;

          inherit (lib)
            concatMapStringsSep
            head
            last
            length
            listToAttrs
            mapAttrs
            mkIf
            strings
            ;

          force = true;

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
              color = ''Color(Single((${generateColor value})))'';
              path = ''Path("${value}")'';
            }
            .${type};

          generateColor =
            color:
            let
              inherit (lib) readFile;
              inherit (pkgs) bc runCommand;
              bcBin = "${bc}/bin/bc";
            in
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
            }/color";

          generateWallpaperMonitor = output: source: seconds: fit: ''
            (
                output: "${output}",
                source: ${generateWallpaper source},
                filter_by_theme: true,
                rotation_frequency: ${toString seconds},
                filter_method: Lanczos,
                scaling_mode: ${if fit then "Fit((0.0, 0.0, 0.0))" else "Zoom"},
                sampling_method: Alphanumeric,
            )
          '';

          perScreen = length monitors > 0;
        in
        {
          home-manager.users = mapAttrs (user: _: {
            home.file = {
              ".config/cosmic/com.system76.CosmicBackground/v1/all" = mkIf (!perScreen) {
                inherit force;
                text = (generateWallpaperMonitor "all" wallpaper seconds fit);
              };

              ".config/cosmic/com.system76.CosmicBackground/v1/backgrounds" = {
                inherit force;
                text =
                  if (perScreen) then
                    ''
                      [
                        ${concatMapStringsSep "," (monitor: ''"${monitor.name}"'') monitors}
                      ]
                    ''
                  else
                    "[]";
              };

              ".config/cosmic/com.system76.CosmicBackground/v1/same-on-all" = {
                inherit force;
                text = if perScreen then "false" else "true";
              };

            }
            // listToAttrs (
              map (
                monitor:
                let
                  inherit (monitor)
                    fit
                    name
                    seconds
                    wallpaper
                    ;
                in
                {
                  name =
                    if
                      (abortIf (name == "") "A cosmic wallpaper monitor setup's name attribute is empty or missing!")
                    then
                      ".config/cosmic/com.system76.CosmicBackground/v1/output.${name}"
                    else
                      "";

                  value = {
                    inherit force;
                    text = (generateWallpaperMonitor name wallpaper seconds fit);
                  };
                }
              ) monitors
            );
          }) users;
        }
      )
    ];

  meta.name = "wallpaper";
}
