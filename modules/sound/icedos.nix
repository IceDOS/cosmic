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
          ...
        }:

        let
          inherit (config.icedos.desktop.cosmic.sound)
            outputAmplification
            inputAmplification
            showMediaControlsInPanel
            ;
        in
        {
          home-manager.sharedModules = [
            {
              xdg.configFile = {
                "cosmic/com.system76.CosmicAudio/v1/amplification_source" = {
                  text = if inputAmplification then "true" else "false";
                };

                "cosmic/com.system76.CosmicAudio/v1/amplification_sink" = {
                  text = if outputAmplification then "true" else "false";
                };
              };

              wayland.desktopManager.cosmic.applets.audio.settings = {
                show_media_controls_in_top_panel = showMediaControlsInPanel;
              };
            }
          ];
        }
      )
    ];

  meta.name = "sound";
}
