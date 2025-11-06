{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.users =
    let
      inherit (icedosLib) mkStrOption mkSubmoduleAttrsOption;
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.users.username) startupScript;
    in
    mkSubmoduleAttrsOption { default = [ ]; } {
      startupScript = mkStrOption { default = startupScript; };
    };

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
          inherit (pkgs) writeShellScriptBin;
          inherit (lib) makeBinPath mapAttrs;
          inherit (config.icedos) desktop users;
        in
        {
          home-manager.users = mapAttrs (
            user: _:
            let
              inherit (desktop.cosmic.users.${user}) startupScript;
            in
            {
              home.file = {
                ".config/autostart/cosmic-startup.desktop" = {
                  text = ''
                    [Desktop Entry]
                    Exec=${
                      makeBinPath [
                        (writeShellScriptBin "cosmic-startup" ''
                          run () {
                            pidof $1 || "$@" &
                          }

                          ${startupScript}
                        '')
                      ]
                    }/cosmic-startup
                    Icon=kitty
                    Name=StartupScript
                    StartupWMClass=startup
                    Terminal=false
                    Type=Application
                  '';
                };
              };
            }
          ) users;
        }
      )
    ];

  meta.name = "startup-script";
}
