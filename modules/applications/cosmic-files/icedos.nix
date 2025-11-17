{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.applications.cosmicFiles =
    let
      inherit (icedosLib)
        mkBoolOption
        mkNumberOption
        mkStrOption
        ;

      inherit
        (
          let
            inherit (lib) readFile;
          in
          (fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.applications.cosmicFiles
        )
        details
        foldersFirst
        hidden
        iconSize
        view
        ;
    in
    {
      details = mkBoolOption { default = details; };
      foldersFirst = mkBoolOption { default = foldersFirst; };
      hidden = mkBoolOption { default = hidden; };
      view = mkStrOption { default = view; };
      iconSize = mkNumberOption { default = iconSize; };
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
          inherit (desktop) cosmic;

          inherit (cosmic.applications.cosmicFiles)
            details
            hidden
            foldersFirst
            iconSize
            view
            ;

          inherit (lib) mapAttrs;
          force = true;
        in
        {
          home-manager.users = mapAttrs (user: _: {
            home.file = {
              ".config/cosmic/com.system76.CosmicFiles/v1/dialog" = {
                inherit force;
                text = ''
                  (
                      folders_first: ${if foldersFirst then "true" else "false"},
                      icon_sizes: (
                          list: ${toString iconSize},
                          grid: ${toString iconSize},
                      ),
                      show_details: ${if details then "true" else "false"},
                      show_hidden: ${if hidden then "true" else "false"},
                      view: ${view},
                  )
                '';
              };

              ".config/cosmic/com.system76.CosmicFiles/v1/tab" = {
                inherit force;
                text = ''
                  (
                      folders_first: ${if foldersFirst then "true" else "false"},
                      icon_sizes: (
                          list: ${toString iconSize},
                          grid: ${toString iconSize},
                      ),
                      show_hidden: ${if hidden then "true" else "false"},
                      single_click: false,
                      view: ${view},
                  )
                '';
              };
            };
          }) users;
        }
      )
    ];

  meta.name = "cosmic-files";
}
