{ icedosLib }:

let
  inherit (icedosLib.color) hexToRgbInts;

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
  # Cosmic stores RGB as 0-1 floats (6-decimal precision via roundFloat).
  hexToRgb = hex: map (i: roundFloat (i / 255.0)) (hexToRgbInts hex);

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
