{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          inherit (config.icedos) users;
          inherit (lib) mapAttrs;

        in
        {
          home-manager.users = mapAttrs (user: _: {
            home.file =
              let
                accentColor =
                  let
                    inherit (config.icedos.desktop) accentColor;
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
                      hex="#${accentColor}"

                      r=$(printf "%d" 0x''${hex:1:2})
                      g=$(printf "%d" 0x''${hex:3:2})
                      b=$(printf "%d" 0x''${hex:5:2})

                      echo "
                        red: $(printTuple $r),
                        green: $(printTuple $g),
                        blue: $(printTuple $b),
                      " > $out/color
                    ''
                  }/color";

                black = ''
                  red: 0.0,
                  green: 0.0,
                  blue: 0.0,
                  alpha: 1.0,
                '';
              in
              {
                ".config/cosmic/com.system76.CosmicTheme.Dark/v1/accent" = {
                  force = true;

                  text = ''
                    (
                        base: (
                          ${accentColor}
                          alpha: 1.0,
                        ),
                        hover: (
                          red: 0.07771457,
                          green: 0.07771458,
                          blue: 0.077714555,
                          alpha: 1.0,
                        ),
                        pressed: (
                          red: 0.04305208,
                          green: 0.04305212,
                          blue: 0.043052074,
                          alpha: 1.0,
                        ),
                        selected: (
                          red: 0.07771457,
                          green: 0.07771458,
                          blue: 0.077714555,
                          alpha: 1.0,
                        ),
                        selected_text: (
                          ${accentColor}
                          alpha: 1.0,
                        ),
                        focus: (
                          ${accentColor}
                          alpha: 1.0,
                        ),
                        divider: (
                          ${black}
                        ),
                        on: (
                          ${black}
                        ),
                        disabled: (
                          ${accentColor}
                          alpha: 1.0,
                        ),
                        on_disabled: (
                          ${accentColor}
                          alpha: 1.0,
                        ),
                        border: (
                          ${accentColor}
                          alpha: 1.0,
                        ),
                        disabled_border: (
                          ${accentColor}
                          alpha: 0.5,
                        ),
                    )
                  '';
                };

                ".config/cosmic/com.system76.CosmicTheme.Dark.Builder/v1/accent" = {
                  force = true;

                  text = ''
                    Some((
                      ${accentColor}
                    ))
                  '';
                };
              };
          }) users;
        }
      )
    ];

  meta.name = "accent-color";
}
