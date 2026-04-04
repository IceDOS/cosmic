{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.dock =
    let
      inherit (icedosLib)
        mkBoolOption
        mkNumberOption
        mkStrListOption
        mkStrOption
        ;

      inherit
        (
          let
            inherit (lib) readFile;
          in
          (fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.dock
        )
        autohide
        enable
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
      enable = mkBoolOption { default = enable; };
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

          inherit (cosmic.dock)
            autohide
            enable
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

          inherit (lib) mapAttrs mkIf;
        in
        {
          home-manager.users = mapAttrs (
            user: _:
            let
              inherit (config.home-manager.users.${user}.lib.cosmic) mkRON;
            in
            {
              wayland.desktopManager.cosmic.panels = mkIf enable [
                {
                  name = "Dock";
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
                  exclusive_zone = false;
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

                  plugins_wings = mkRON "optional" (mkRON "tuple" [
                    left
                    right
                  ]);

                  size = mkRON "enum" size;
                  spacing = 0;
                  border_radius = 12;

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
            }
          ) users;
        }
      )
    ];

  meta.name = "dock";
}
