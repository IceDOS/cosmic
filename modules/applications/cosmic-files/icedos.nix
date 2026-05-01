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
          ...
        }:
        let
          inherit (config.icedos.desktop.cosmic.applications.cosmicFiles)
            details
            hidden
            foldersFirst
            iconSize
            view
            ;

          force = true;
        in
        {
          home-manager.sharedModules = [
            {
              xdg.configFile = {
                "cosmic/com.system76.CosmicFiles/v1/dialog" = {
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

                "cosmic/com.system76.CosmicFiles/v1/tab" = {
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
            }
          ];
        }
      )
    ];

  meta.name = "cosmic-files";
}
