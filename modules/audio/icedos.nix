{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.audio =
    let
      inherit (icedosLib) mkBoolOption;

      inherit
        (
          let
            inherit (lib) readFile;
          in
          (fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.audio
        )
        outputAmplification
        inputAmplification
        ;
    in
    {
      outputAmplification = mkBoolOption { default = outputAmplification; };
      inputAmplification = mkBoolOption { default = inputAmplification; };
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

          inherit (cosmic.audio)
            outputAmplification
            inputAmplification
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
          }) users;
        }
      )
    ];

  meta.name = "audio";
}
