{ lib }:

let
  inherit (lib) toLower;

  hexChars = "0123456789abcdef";

  hexDigitToInt = c: builtins.stringLength (builtins.head (builtins.split (toLower c) hexChars));

  hexToInt =
    hex:
    let
      len = builtins.stringLength hex;
      go =
        i: acc:
        if i >= len then acc else go (i + 1) (acc * 16 + hexDigitToInt (builtins.substring i 1 hex));
    in
    go 0 0;

  roundFloat = f: builtins.floor (f * 1000000 + 0.5) / 1000000.0;

  # e^x via Taylor series (25 terms, precise for |x| < 10)
  exp =
    x:
    let
      go =
        n: term: sum:
        if n > 25 then sum else go (n + 1) (term * x / n) (sum + term);
    in
    go 1 1.0 0.0;

  ln2 = 0.6931471805599453;
in
{
  hexToRgb = hex: [
    (roundFloat ((hexToInt (builtins.substring 0 2 hex)) / 255.0))
    (roundFloat ((hexToInt (builtins.substring 2 2 hex)) / 255.0))
    (roundFloat ((hexToInt (builtins.substring 4 2 hex)) / 255.0))
  ];

  # 2^x, used for scroll speed: 2^((0.1 * speed) - 5)
  pow2 = x: exp (x * ln2);

  # Maps 0-100 to cosmic's mouse speed range (-0.81..0.60)
  mouseSpeedToCosmicSpeed =
    speed:
    let
      slope = 0.014142271248762554;
      y = -0.8099999999999998;
    in
    roundFloat ((slope * speed) + y);
}
