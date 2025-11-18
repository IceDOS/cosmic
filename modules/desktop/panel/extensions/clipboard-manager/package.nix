{
  fetchFromGitHub,
  just,
  lib,
  libcosmicAppHook,
  rustPlatform,
  stdenv,
}:

rustPlatform.buildRustPackage (
  let
    inherit (lib) substring;
    rev = "f74b562a09e88e8d20ee0b9c5ab8cade8e4edbdb";
    version = substring 0 8 rev;
  in
  {
    inherit version;
    pname = "cosmic-ext-applet-clipboard-manager";

    src = fetchFromGitHub {
      owner = "cosmic-utils";
      repo = "clipboard-manager";
      rev = "f74b562a09e88e8d20ee0b9c5ab8cade8e4edbdb";
      hash = "sha256-tWNf0YZzVXM8FsA/jhGSrdPvnLRaVzQ1prYWINAGNN8=";
    };

    cargoHash = "sha256-DmxrlYhxC1gh5ZoPwYqJcAPu70gzivFaZQ7hVMwz3aY=";

    nativeBuildInputs = [
      libcosmicAppHook
      just
    ];

    dontUseJustBuild = true;
    dontUseJustCheck = true;

    justFlags = [
      "--set"
      "prefix"
      (placeholder "out")
      "--set"
      "bin-src"
      "target/${stdenv.hostPlatform.rust.cargoShortTarget}/release/cosmic-ext-applet-clipboard-manager"
    ];

    preBuild = ''
      substituteInPlace "justfile" --replace-fail 'export CLIPBOARD_MANAGER_COMMIT := `git rev-parse --short HEAD`' ""
    '';

    CLIPBOARD_MANAGER_COMMIT = version;

    preCheck = ''
      export XDG_RUNTIME_DIR="$TMP"
    '';
  }
)
