{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      {
        services.desktopManager.cosmic.enable = true;
      }
    ];

  meta.name = "default";
}
