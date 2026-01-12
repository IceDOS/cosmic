{
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "cos-cli";
  version = "unstable-2026-20-01";

  src = fetchFromGitHub {
    owner = "estin";
    repo = pname;
    rev = "9c23bd2f66b05e54e36a82f6dc93c14a62fc054f";
    hash = "sha256-xTRJjgi3FDCKoxRdQU6Xuf2vV5PEZXWhNcon17LIbfw=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;

    outputHashes = {
      "cosmic-protocols-0.2.0" = "sha256-ymn+BUTTzyHquPn4hvuoA3y1owFj8LVrmsPu2cdkFQ8=";
    };
  };
}
