{
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "cos-cli";
  version = "unstable-2025-01-12";

  src = fetchFromGitHub {
    owner = "estin";
    repo = pname;
    rev = "b87256a534f4043725fe31386156b9ae21847bee";
    hash = "sha256-YTxSSufQDluXb+mKmT8ECftpyAhXpFs4Au4iG/quJow=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;

    outputHashes = {
      "cosmic-protocols-0.2.0" = "sha256-ymn+BUTTzyHquPn4hvuoA3y1owFj8LVrmsPu2cdkFQ8=";
    };
  };
}
