{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.sound =
    let
      inherit (icedosLib) mkBoolOption;

      inherit
        (
          let
            inherit (lib) readFile;
          in
          (fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.sound
        )
        outputAmplification
        inputAmplification
        showMediaControlsInPanel
        ;
    in
    {
      outputAmplification = mkBoolOption { default = outputAmplification; };
      inputAmplification = mkBoolOption { default = inputAmplification; };
      showMediaControlsInPanel = mkBoolOption { default = showMediaControlsInPanel; };
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

          inherit (cosmic.sound)
            outputAmplification
            inputAmplification
            showMediaControlsInPanel
            ;

          inherit (lib) mapAttrs;
          force = true;
        in
        {
          home-manager.users = mapAttrs (user: _: {
            home.file = {
              ".config/cosmic/com.system76.CosmicAudio/v1/amplification_source" = {
                inherit force;
                text = if outputAmplification then "true" else "false";
              };

              ".config/cosmic/com.system76.CosmicAudio/v1/amplification_sink" = {
                inherit force;
                text = if inputAmplification then "true" else "false";
              };
            };

            wayland.desktopManager.cosmic.applets.audio.settings = {
              show_media_controls_in_top_panel = showMediaControlsInPanel;
            };
          }) users;
        }
      )
    ];

  meta.name = "sound";
}
