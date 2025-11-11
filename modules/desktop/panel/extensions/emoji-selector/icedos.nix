{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      (
        {
          pkgs,
          ...
        }:

        {
          nixpkgs.overlays = [
            (final: super: {
              cosmic-ext-applet-emoji-selector = final.callPackage ./package.nix { };
            })
          ];

          environment.systemPackages =
            let
              inherit (pkgs) cosmic-ext-applet-emoji-selector;
            in
            [
              cosmic-ext-applet-emoji-selector
            ];
        }
      )
    ];

  meta.name = "emoji-selector";
}
