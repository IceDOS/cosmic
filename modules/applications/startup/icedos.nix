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
          inherit (lib) mapAttrs;
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
                    Exec=${writeShellScriptBin "cosmic-startup" ''
                      base_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
                      nix_system_path="/run/current-system/sw/bin"
                      nix_user_path="''${HOME}/.nix-profile/bin"
                      export PATH="''${base_path}:''${nix_system_path}:''${nix_user_path}:$PATH"

                      ${startupScript}
                    ''}/bin/cosmic-startup
                    Icon=kitty
                    Name=StartupScript
                    StartupWMClass=startup
                    Terminal=true
                    Type=Application
                  '';
                };
              };
            }
          ) users;
        }
      )
    ];

  meta.name = "startup";
}
