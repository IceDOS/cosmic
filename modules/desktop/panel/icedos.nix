{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic =
    let
      inherit (icedosLib)
        mkBoolOption
        mkNumberOption
        mkStrListOption
        mkStrOption
        mkSubmoduleAttrsOption
        ;

      inherit
        (
          let
            inherit (lib) readFile;
          in
          (fromTOML (readFile ./config.toml)).icedos.desktop.cosmic
        )
        panel
        users
        ;

      inherit (panel)
        autohide
        expand
        gaps
        monitor
        opacity
        plugins
        position
        size
        themeMode
        ;

      inherit (plugins) center left right;
    in
    {
      panel = {
        autohide = mkBoolOption { default = autohide; };
        expand = mkBoolOption { default = expand; };
        gaps = mkBoolOption { default = gaps; };
        monitor = mkStrOption { default = monitor; };
        opacity = mkNumberOption { default = opacity; };

        plugins = {
          center = mkStrListOption { default = center; };
          left = mkStrListOption { default = left; };
          right = mkStrListOption { default = right; };
        };

        position = mkStrOption { default = position; };
        size = mkStrOption { default = size; };
        themeMode = mkStrOption { default = themeMode; };
      };

      users = mkSubmoduleAttrsOption { } {
        panelFavorites = mkStrListOption { default = users.username.panelFavorites; };
      };
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
          inherit (config.icedos) users;
          inherit (lib) mapAttrs;
        in
        {
          home-manager.users = mapAttrs (
            user: _:
            let
              inherit (config.icedos) desktop;
              inherit (desktop) cosmic;
              inherit (cosmic) panel users;

              inherit (panel)
                autohide
                expand
                gaps
                monitor
                opacity
                plugins
                position
                size
                themeMode
                ;

              inherit (users.${user}) panelFavorites;

              inherit (plugins) center left right;

              inherit (lib)
                concatMapStringsSep
                mkIf
                length
                ;
              force = true;
            in
            {
              home.file = {
                ".config/cosmic/com.system76.CosmicPanel.Panel/v1/anchor" = {
                  inherit force;
                  text = position;
                };

                ".config/cosmic/com.system76.CosmicPanel.Panel/v1/anchor_gap" = {
                  inherit force;
                  text = if gaps then "true" else "false";
                };

                ".config/cosmic/com.system76.CosmicPanel.Panel/v1/autohide" = {
                  inherit force;
                  text =
                    if autohide then
                      ''
                        Some((
                            wait_time: 1000,
                            transition_time: 200,
                            handle_size: 4,
                            unhide_delay: 200,
                        ))
                      ''
                    else
                      "None";
                };

                ".config/cosmic/com.system76.CosmicPanel.Panel/v1/background" = {
                  inherit force;
                  text = themeMode;
                };

                ".config/cosmic/com.system76.CosmicPanel.Panel/v1/exclusive_zone" = {
                  inherit force;
                  text = if autohide then "true" else "false";
                };

                ".config/cosmic/com.system76.CosmicPanel.Panel/v1/expand_to_edges" = {
                  inherit force;
                  text = if expand then "true" else "false";
                };

                ".config/cosmic/com.system76.CosmicPanel.Panel/v1/plugins_center" = {
                  inherit force;

                  text = ''
                    Some([
                        ${(concatMapStringsSep "" (plugin: ''"${plugin}",'') center)}
                    ])
                  '';
                };

                ".config/cosmic/com.system76.CosmicPanel.Panel/v1/plugins_wings" = {
                  inherit force;

                  text = ''
                    Some(([
                        ${(concatMapStringsSep "" (plugin: ''"${plugin}",'') left)}
                    ], [
                        ${(concatMapStringsSep "" (plugin: ''"${plugin}",'') right)}
                    ]))
                  '';
                };

                ".config/cosmic/com.system76.CosmicPanel.Panel/v1/opacity" = {
                  inherit force;
                  text = "${toString (opacity / 100)}.0";
                };

                ".config/cosmic/com.system76.CosmicPanel.Panel/v1/output" = {
                  inherit force;
                  text = if (monitor == "") then "All" else ''Name("${monitor}")'';
                };

                ".config/cosmic/com.system76.CosmicPanel.Panel/v1/size" = {
                  inherit force;
                  text = size;
                };
              };

              wayland.desktopManager.cosmic.applets.app-list.settings.favorites = mkIf (
                (length panelFavorites) > 0
              ) panelFavorites;
            }
          ) users;
        }
      )
    ];

  meta.name = "panel";
}
