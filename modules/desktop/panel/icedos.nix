{ icedosLib, lib, ... }:

{
  options.icedos.desktop =
    let
      inherit (icedosLib)
        mkBoolOption
        mkNumberOption
        mkStrListOption
        mkStrOption
        mkSubmoduleAttrsOption
        ;

      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.desktop) cosmic users;
      inherit (cosmic) panel;

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
      cosmic.panel = {
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

      # Contributes `cosmic` to the desktop per-user submodule (declared in
      # icedos/desktop). cosmic per-user config lives at
      # icedos.desktop.users.<name>.cosmic and materialises via desktop's genDefaults.
      users = mkSubmoduleAttrsOption { default = { }; } {
        cosmic.panelFavorites = mkStrListOption { default = users.username.cosmic.panelFavorites; };
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
          inherit (config.icedos) desktop;
          inherit (desktop) cosmic;
          inherit (cosmic) panel;
          inherit (lib) mkIf length;

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
          home-manager.sharedModules = [
            (
              { config, ... }:

              let
                inherit (desktop.users.${config.home.username}.cosmic) panelFavorites;
                inherit (config.lib.cosmic) mkRON;
              in
              {
                wayland.desktopManager.cosmic.panels = [
                  {
                    name = "Panel";
                    anchor = mkRON "enum" position;
                    anchor_gap = gaps;

                    autohide =
                      if autohide then
                        mkRON "optional" {
                          wait_time = 1000;
                          transition_time = 200;
                          handle_size = 4;
                          unhide_delay = 200;
                        }
                      else
                        {
                          __type = "optional";
                          value = null;
                        };

                    background = mkRON "enum" themeMode;
                    exclusive_zone = !autohide;
                    expand_to_edges = expand;
                    keyboard_interactivity = mkRON "enum" "OnDemand";
                    layer = mkRON "enum" "Top";
                    margin = 0;
                    opacity = opacity / 100.0;

                    output =
                      if (monitor == "") then
                        mkRON "enum" "All"
                      else
                        {
                          __type = "enum";
                          variant = "Name";
                          value = [ monitor ];
                        };

                    padding = 0;

                    plugins_center = mkRON "optional" center;

                    plugins_wings = mkRON "optional" (
                      mkRON "tuple" [
                        left
                        right
                      ]
                    );

                    size = mkRON "enum" size;
                    spacing = 0;
                    border_radius = 0;

                    size_wings = {
                      __type = "optional";
                      value = null;
                    };

                    size_center = {
                      __type = "optional";
                      value = null;
                    };

                    autohover_delay_ms = mkRON "optional" 500;
                    padding_overlap = 0.5;
                  }
                ];

                wayland.desktopManager.cosmic.applets.app-list.settings.favorites = mkIf (
                  (length panelFavorites) > 0
                ) panelFavorites;
              }
            )
          ];
        }
      )
    ];

  meta.name = "panel";
}
