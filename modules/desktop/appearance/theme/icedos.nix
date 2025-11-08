{ icedosLib, lib, ... }:

{
  options.icedos.desktop.cosmic.theme =
    let
      inherit (icedosLib) mkBoolOption mkStrOption;
      inherit
        (
          let
            inherit (lib) readFile;
          in
          (fromTOML (readFile ./config.toml)).icedos.desktop.cosmic.theme
        )
        gtkTheming
        mode
        ;
    in
    {
      gtkTheming = mkBoolOption { default = gtkTheming; };
      mode = mkStrOption { default = mode; };
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          inherit (config.icedos) desktop users;
          inherit (desktop) accentColor;
          inherit (desktop.cosmic.theme) gtkTheming mode;

          inherit (lib)
            elemAt
            isBool
            mapAttrs
            mkIf
            readFile
            splitString
            ;

          force = true;

          generateColor =
            color: string:
            let
              inherit (pkgs) bc runCommand;
              bcBin = "${bc}/bin/bc";
            in
            splitString "," (
              readFile "${runCommand "hex-to-rgb-tuple" { } ''
                function printTuple() {
                  echo "scale=8; $1/255" | ${bcBin}
                }

                function editColor() {
                    _r=$1
                    _g=$2
                    _b=$3

                    ((r += _r))
                    ((g += _g))
                    ((b += _b))

                    r=$(normalizeColor $r)
                    g=$(normalizeColor $g)
                    b=$(normalizeColor $b)
                }

                function normalizeColor() {
                  current_color=$1

                  if (( $1 < 0 )); then
                    current_color=0
                  elif (( $1 > 255 )); then
                    current_color=255
                  fi

                  echo $current_color
                }

                hex="#${color}"

                r=$(printf "%d" 0x''${hex:1:2})
                g=$(printf "%d" 0x''${hex:3:2})
                b=$(printf "%d" 0x''${hex:5:2})

                ${
                  if (string == "heavy") then
                    "editColor -6 2 -19"
                  else if (string == "heavier") then
                    "editColor -53 -33 -86"
                  else if (string == "heaviest") then
                    "editColor -64 -43 -97"
                  else
                    ""
                }

                r=$(printTuple $r)
                g=$(printTuple $g)
                b=$(printTuple $b)

                [[ (( $r < 1 )) ]] && r="0$r" || r="1.0"
                [[ (( $g < 1 )) ]] && g="0$g" || g="1.0"
                [[ (( $b < 1 )) ]] && b="0$b" || b="1.0"

                echo "$r, $g, $b," > $out
              ''}"
            );

          generateRgbArray =
            name: rgb: alpha:
            let
              red = toString (elemAt rgb 0);
              green = toString (elemAt rgb 1);
              blue = toString (elemAt rgb 2);
            in
            "${name}: (red: ${red}, green: ${green}, blue: ${blue}, alpha: ${toString alpha}),";

          generateObject =
            rgb: alpha:
            let
              red = toString (elemAt rgb 0);
              green = toString (elemAt rgb 1);
              blue = toString (elemAt rgb 2);
            in
            "Some((red: ${red}, green: ${green}, blue: ${blue}, ${
              if (!(isBool alpha)) then "alpha: ${toString alpha}" else ""
            }))";
        in
        {
          home-manager.users = mapAttrs (user: _: {
            home.file =
              let
                accent = generateColor accentColor "";
                heavy = generateColor accentColor "heavy";
                heavier = generateColor accentColor "heavier";
                heaviest = generateColor accentColor "heaviest";
                isAuto = mode == "auto";
              in
              {
                ".config/cosmic/com.system76.CosmicTheme.Dark/v1/accent" = {
                  inherit force;

                  text = ''
                    (
                      ${generateRgbArray "base" accent 1.0}
                      ${generateRgbArray "hover" heavy 1.0}
                      ${generateRgbArray "pressed" heavier 1.0}
                      ${generateRgbArray "selected" accent 1.0}
                      ${generateRgbArray "selected_text" accent 1.0}
                      ${generateRgbArray "focus" accent 1.0}
                      ${generateRgbArray "divider" [ 0.0 0.0 0.0 ] 1.0}
                      ${generateRgbArray "on" [ 0.0 0.0 0.0 ] 1.0}
                      ${generateRgbArray "disabled" accent 1.0}
                      ${generateRgbArray "on_disabled" heaviest 1.0}
                      ${generateRgbArray "border" accent 1.0}
                      ${generateRgbArray "disabled_border" accent 0.5}
                    )
                  '';
                };

                ".config/cosmic/com.system76.CosmicTheme.Dark/v1/accent_button" = {
                  inherit force;

                  text = ''
                    (
                      ${generateRgbArray "base" accent 1.0}
                      ${generateRgbArray "hover" heavy 1.0}
                      ${generateRgbArray "pressed" heavier 1.0}
                      ${generateRgbArray "selected" heavy 1.0}
                      ${generateRgbArray "selected_text" accent 1.0}
                      ${generateRgbArray "focus" accent 1.0}
                      ${generateRgbArray "divider" [ 0.0129199885 0.01292001 0.012919978 ] 1.0}
                      ${generateRgbArray "on" [ 0.0 0.0 0.0 ] 1.0}
                      ${generateRgbArray "disabled" accent 1.0}
                      ${generateRgbArray "on_disabled" [ 0.0 0.0 0.0 ] 0.5}
                      ${generateRgbArray "border" accent 1.0}
                      ${generateRgbArray "disabled_border" accent 0.5}
                    )
                  '';
                };

                ".config/cosmic/com.system76.CosmicTheme.Dark/v1/accent_text" = {
                  inherit force;
                  text = generateObject accent 1.0;
                };

                ".config/cosmic/com.system76.CosmicTheme.Dark/v1/background" = {
                  inherit force;

                  text = ''
                    (
                      ${generateRgbArray "base" [ 0.10588235 0.10588235 0.10588235 ] 1.0}
                      component: (
                        ${generateRgbArray "base" [ 0.18219745 0.18219745 0.18219745 ] 1.0}
                        ${generateRgbArray "hover" [ 0.2639777 0.2639777 0.26397768 ] 1.0}
                        ${generateRgbArray "pressed" [ 0.34575796 0.34575796 0.34575796 ] 1.0}
                        ${generateRgbArray "selected" [ 0.2639777 0.2639777 0.26397768 ] 1.0}
                        ${generateRgbArray "selected_text" accent 1.0}
                        ${generateRgbArray "focus" accent 1.0}
                        ${generateRgbArray "divider" [ 0.7532969 0.7532969 0.75329685 ] 0.2}
                        ${generateRgbArray "on" [ 0.7532969 0.7532969 0.75329685 ] 1.0}
                        ${generateRgbArray "disabled" [ 0.18219745 0.18219745 0.18219745 ] 0.5}
                        ${generateRgbArray "on_disabled" [ 0.7532969 0.7532969 0.75329685 ] 0.65}
                        ${generateRgbArray "border" [ 0.7432059 0.7432059 0.7432057 ] 1.0}
                        ${generateRgbArray "disabled_border" [ 0.7432059 0.7432059 0.7432057 ] 0.5}
                      ),
                      ${generateRgbArray "divider" [ 0.2662247 0.2662247 0.2662247 ] 1.0}
                      ${generateRgbArray "on" [ 0.90759414 0.9075942 0.90759414 ] 1.0}
                      ${generateRgbArray "base" [ 0.15292808 0.15292811 0.15292805 ] 0.25}
                    )
                  '';
                };

                ".config/cosmic/com.system76.CosmicTheme.Dark/v1/button" = {
                  inherit force;

                  text = ''
                    (
                      ${generateRgbArray "base" [ 0.6204993 0.62049943 0.6204992 ] 0.25}
                      ${generateRgbArray "hover" [ 0.38796422 0.3879643 0.38796416 ] 0.4}
                      ${generateRgbArray "pressed" [ 0.16715194 0.167152 0.16715191 ] 0.625}
                      ${generateRgbArray "selected" [ 0.38796422 0.3879643 0.38796416 ] 0.4}
                      ${generateRgbArray "selected_text" accent 1.0}
                      ${generateRgbArray "focus" accent 1.0}
                      ${generateRgbArray "divider" [ 0.7532969 0.7532969 0.75329685 ] 0.2}
                      ${generateRgbArray "on" [ 0.7532969 0.7532969 0.75329685 ] 1.0}
                      ${generateRgbArray "disabled" [ 0.6204993 0.62049943 0.6204992 ] 0.125}
                      ${generateRgbArray "on_disabled" [ 0.7532969 0.7532969 0.75329685 ] 0.65}
                      ${generateRgbArray "border" [ 0.7432059 0.7432059 0.7432057 ] 1.0}
                      ${generateRgbArray "disabled_border" [ 0.7432059 0.7432059 0.7432057 ] 0.5}
                    )
                  '';
                };

                ".config/cosmic/com.system76.CosmicTheme.Dark/v1/destructive" = {
                  inherit force;

                  text = ''
                    (
                      ${generateRgbArray "base" [ 0.9215686 0.6313726 0.627451 ] 1.0}
                      ${generateRgbArray "hover" [ 0.87144005 0.5828126 0.5796754 ] 1.0}
                      ${generateRgbArray "pressed" [ 0.5391305 0.3587384 0.35677758 ] 1.0}
                      ${generateRgbArray "selected" [ 0.87144005 0.5828126 0.5796754 ] 1.0}
                      ${generateRgbArray "selected_text" accent 1.0}
                      ${generateRgbArray "focus" accent 1.0}
                      ${generateRgbArray "divider" [ 0.0 0.0 0.0 ] 1.0}
                      ${generateRgbArray "on" [ 0.0 0.0 0.0 ] 1.0}
                      ${generateRgbArray "disabled" [ 0.9215686 0.6313726 0.627451 ] 1.0}
                      ${generateRgbArray "on_disabled" [ 0.49607843 0.3156863 0.3137255 ] 1.0}
                      ${generateRgbArray "border" [ 0.9215686 0.6313726 0.627451 ] 1.0}
                      ${generateRgbArray "disabled_border" [ 0.9215686 0.6313726 0.627451 ] 0.5}
                    )
                  '';
                };

                ".config/cosmic/com.system76.CosmicTheme.Dark/v1/destructive_button" = {
                  inherit force;

                  text = ''
                    (
                      ${generateRgbArray "base" [ 0.9215686 0.6313726 0.627451 ] 1.0}
                      ${generateRgbArray "hover" [ 0.87144005 0.5828126 0.5796754 ] 1.0}
                      ${generateRgbArray "pressed" [ 0.5391305 0.3587384 0.3567758 ] 1.0}
                      ${generateRgbArray "selected" [ 0.87144005 0.5828126 0.5796754 ] 1.0}
                      ${generateRgbArray "selected_text" accent 1.0}
                      ${generateRgbArray "focus" accent 1.0}
                      ${generateRgbArray "divider" [ 0.0129199885 0.01292001 0.012919978 ] 1.0}
                      ${generateRgbArray "on" [ 0.0 0.0 0.0 ] 1.0}
                      ${generateRgbArray "disabled" [ 0.9215686 0.6313726 0.627451 ] 1.0}
                      ${generateRgbArray "on_disabled" [ 0.0 0.0 0.0 ] 0.5}
                      ${generateRgbArray "border" [ 0.9215686 0.6313726 0.627451 ] 1.0}
                      ${generateRgbArray "disabled_border" [ 0.99215686 0.6313726 0.627451 ] 0.5}
                    )
                  '';
                };

                ".config/cosmic/com.system76.CosmicTheme.Dark/v1/icon_button" = {
                  inherit force;

                  text = ''
                    (
                      ${generateRgbArray "base" [ 0.0 0.0 0.0 ] 0.0}
                      ${generateRgbArray "hover" [ 0.38857284 0.38857287 0.3857278 ] 0.2}
                      ${generateRgbArray "pressed" [ 0.08610416 0.08610424 0.08610415 ] 0.5}
                      ${generateRgbArray "selected" [ 0.38857284 0.38857287 0.3857278 ] 0.2}
                      ${generateRgbArray "selected_text" accent 1.0}
                      ${generateRgbArray "focus" accent 1.0}
                      ${generateRgbArray "divider" [ 0.7432059 0.7432059 0.7432057 ] 0.2}
                      ${generateRgbArray "on" [ 0.7432059 0.7432059 0.7432057 ] 1.0}
                      ${generateRgbArray "disabled" [ 0.0 0.0 0.0 ] 0.0}
                      ${generateRgbArray "on_disabled" [ 0.7432059 0.7432059 0.7432057 ] 0.65}
                      ${generateRgbArray "border" [ 0.7432059 0.7432059 0.7432057 ] 1.0}
                      ${generateRgbArray "disabled_border" [ 0.7432059 0.7432059 0.7432057 ] 0.5}
                    )
                  '';
                };

                ".config/cosmic/com.system76.CosmicTheme.Dark/v1/link_button" = {
                  inherit force;

                  text = ''
                    (
                      ${generateRgbArray "base" [ 0.0 0.0 0.0 ] 0.0}
                      ${generateRgbArray "hover" [ 0.0 0.0 0.0 ] 0.0}
                      ${generateRgbArray "pressed" [ 0.0 0.0 0.0 ] 0.0}
                      ${generateRgbArray "selected" [ 0.0 0.0 0.0 ] 0.0}
                      ${generateRgbArray "selected_text" accent 1.0}
                      ${generateRgbArray "focus" accent 1.0}
                      ${generateRgbArray "divider" [ 0.754545 0.6429985 1.0 ] 0.2}
                      ${generateRgbArray "on" [ 0.754545 0.6429985 1.0 ] 1.0}
                      ${generateRgbArray "disabled" [ 0.0 0.0 0.0 ] 0.0}
                      ${generateRgbArray "on_disabled" heavy 0.5}
                      ${generateRgbArray "border" [ 0.7432059 0.7432059 0.7432057 ] 1.0}
                      ${generateRgbArray "disabled_border" [ 0.7432059 0.7432059 0.7432057 ] 0.5}
                    )
                  '';
                };

                ".config/cosmic/com.system76.CosmicTheme.Dark/v1/primary" = {
                  inherit force;

                  text = ''
                    (
                      ${generateRgbArray "base" [ 0.15292811 0.15292811 0.15292808 ] 1.0}
                      component: (
                        ${generateRgbArray "base" [ 0.21220893 0.21220893 0.2120881 ] 1.0}
                        ${generateRgbArray "hover" [ 0.29098803 0.29098803 0.29098788 ] 1.0}
                        ${generateRgbArray "pressed" [ 0.36976713 0.36976713 0.369767 ] 1.0}
                        ${generateRgbArray "selected" [ 0.29098803 0.29098803 0.29098788 ] 1.0}
                        ${generateRgbArray "selected_text" accent 1.0}
                        ${generateRgbArray "focus" accent 1.0}
                        ${generateRgbArray "divider" [ 0.7913618 0.7913618 0.7913618 ] 0.2}
                        ${generateRgbArray "on" [ 0.7913618 0.7913618 0.7913618 ] 1.0}
                        ${generateRgbArray "disabled" [ 0.21220893 0.21220893 0.2120881 ] 0.5}
                        ${generateRgbArray "on_disabled" [ 0.7913618 0.7913618 0.7913618 ] 0.65}
                        ${generateRgbArray "border" [ 0.7432059 0.7432059 0.7432057 ] 1.0}
                        ${generateRgbArray "disabled_border" [ 0.7432059 0.7432059 0.7432057 ] 0.5}
                      ),
                      ${generateRgbArray "divider" [ 0.31702772 0.31702772 0.3170277 ] 1.0}
                      ${generateRgbArray "on" [ 0.97342616 0.97342616 0.97342604 ] 1.0}
                      ${generateRgbArray "small_widget" [ 0.20212594 0.202126 0.2021259 ] 0.25}
                    )
                  '';
                };

                ".config/cosmic/com.system76.CosmicTheme.Dark/v1/secondary" = {
                  inherit force;

                  text = ''
                    (
                      ${generateRgbArray "base" [ 0.20212594 0.20212597 0.20212597 ] 1.0}
                      component: (
                        ${generateRgbArray "base" [ 0.23260304 0.23260310 0.23260301 ] 1.0}
                        ${generateRgbArray "hover" [ 0.30934274 0.30934280 0.30934268 ] 1.0}
                        ${generateRgbArray "pressed" [ 0.38608240 0.38608247 0.38608235 ] 1.0}
                        ${generateRgbArray "selected" [ 0.30934274 0.30934280 0.30934268 ] 1.0}
                        ${generateRgbArray "selected_text" accent 1.0}
                        ${generateRgbArray "focus" accent 1.0}
                        ${generateRgbArray "divider" [ 0.81693083 0.81693090 0.81693090 ] 0.2}
                        ${generateRgbArray "on" [ 0.81693083 0.81693090 0.81693090 ] 1.0}
                        ${generateRgbArray "disabled" [ 0.23260304 0.23260310 0.23260301 ] 0.5}
                        ${generateRgbArray "on_disabled" [ 0.81693083 0.81693090 0.81693090 ] 0.65}
                        ${generateRgbArray "border" [ 0.7432059 0.7432059 0.7432057 ] 1.0}
                        ${generateRgbArray "disabled_border" [ 0.74320590 0.74320590 0.74320570 ] 0.5}
                      ),
                      ${generateRgbArray "divider" [ 0.3174277 0.31742772 0.3174277 ] 1.0}
                      ${generateRgbArray "on" [ 0.7786347 0.7786347 0.77863467 ] 1.0}
                      ${generateRgbArray "small_widget" [ 0.2532908 0.25329086 0.25329074 ] 0.25}
                    )
                  '';
                };

                ".config/cosmic/com.system76.CosmicTheme.Dark/v1/success" = {
                  inherit force;

                  text = ''
                    (
                      ${generateRgbArray "base" [ 0.57254905 0.8117647 0.617647 ] 1.0}
                      ${generateRgbArray "hover" [ 0.53575385 0.72712636 0.56712633 ] 1.0}
                      ${generateRgbArray "pressed" [ 0.3293266 0.4893447 0.34893444 ] 1.0}
                      ${generateRgbArray "selected" [ 0.53575385 0.72712636 0.56712633 ] 1.0}
                      ${generateRgbArray "selected_text" accent 1.0}
                      ${generateRgbArray "focus" accent 1.0}
                      ${generateRgbArray "divider" [ 0.0 0.0 0.0 ] 1.0}
                      ${generateRgbArray "on" [ 0.0 0.0 0.0 ] 1.0}
                      ${generateRgbArray "disabled" [ 0.57254905 0.8117647 0.617647 ] 1.0}
                      ${generateRgbArray "on_disabled" [ 0.28627452 0.40588236 0.3058236 ] 1.0}
                      ${generateRgbArray "border" [ 0.57254905 0.8117647 0.617647 ] 1.0}
                      ${generateRgbArray "disabled_border" [ 0.57254905 0.8117647 0.617647 ] 0.5}
                    )
                  '';
                };

                ".config/cosmic/com.system76.CosmicTheme.Dark/v1/text_button" = {
                  inherit force;

                  text = ''
                    (
                      ${generateRgbArray "base" [ 0.0 0.0 0.0 ] 0.0}
                      ${generateRgbArray "hover" [ 0.38857284 0.38857287 0.38857278 ] 0.2}
                      ${generateRgbArray "pressed" [ 0.08610416 0.08610424 0.08610415 ] 0.5}
                      ${generateRgbArray "selected" [ 0.38857284 0.38857287 0.38857278 ] 0.2}
                      ${generateRgbArray "selected_text" accent 1.0}
                      ${generateRgbArray "focus" accent 1.0}
                      ${generateRgbArray "divider" [ 0.754545 0.6429985 1.0 ] 0.2}
                      ${generateRgbArray "on" [ 0.754545 0.6429985 1.0 ] 1.0}
                      ${generateRgbArray "disabled" [ 0.0 0.0 0.0 ] 0.0}
                      ${generateRgbArray "on_disabled" [ 0.754545 0.6429985 1.0 ] 0.65}
                      ${generateRgbArray "border" [ 0.7432059 0.7432059 0.7432057 ] 1.0}
                      ${generateRgbArray "disabled_border" [ 0.7432059 0.7432059 0.7432057 ] 0.5}
                    )
                  '';
                };

                ".config/cosmic/com.system76.CosmicTheme.Dark/v1/warning" = {
                  inherit force;

                  text = ''
                    (
                      ${generateRgbArray "base" [ 0.96862745 0.8784314 0.38431373 ] 1.0}
                      ${generateRgbArray "hover" [ 0.85261655 0.7804597 0.38516554 ] 1.0}
                      ${generateRgbArray "pressed" [ 0.5273658 0.4822678 0.23520894 ] 1.0}
                      ${generateRgbArray "selected" [ 0.85261655 0.7804597 0.38516554 ] 1.0}
                      ${generateRgbArray "selected_text" accent 1.0}
                      ${generateRgbArray "focus" accent 1.0}
                      ${generateRgbArray "divider" [ 0.0 0.0 0.0 ] 1.0}
                      ${generateRgbArray "on" [ 0.0 0.0 0.0 ] 1.0}
                      ${generateRgbArray "disabled" [ 0.96862745 0.8784314 0.38431373 ] 1.0}
                      ${generateRgbArray "on_disabled" [ 0.48431373 0.4392157 0.19215687 ] 1.0}
                      ${generateRgbArray "border" [ 0.96862745 0.8784314 0.38431373 ] 1.0}
                      ${generateRgbArray "disabled_border" [ 0.96862745 0.8784314 0.38431373 ] 0.5}
                    )
                  '';
                };

                ".config/cosmic/com.system76.CosmicTheme.Dark/v1/warning_button" = {
                  inherit force;

                  text = ''
                    (
                      ${generateRgbArray "base" [ 0.96862745 0.87843140 0.38431373 ] 1.0}
                      ${generateRgbArray "hover" [ 0.85261655 0.78045970 0.38516554 ] 1.0}
                      ${generateRgbArray "pressed" [ 0.52736580 0.48226780 0.23520894 ] 1.0}
                      ${generateRgbArray "selected" [ 0.85261655 0.78045970 0.38516554 ] 1.0}
                      ${generateRgbArray "selected_text" accent 1.0}
                      ${generateRgbArray "focus" accent 1.0}
                      ${generateRgbArray "divider" [ 0.9999994 0.99999994 0.99970 ] 1.0}
                      ${generateRgbArray "on" [ 0.0 0.0 0.0 ] 1.0}
                      ${generateRgbArray "disabled" [ 0.96862745 0.87843140 0.38431373 ] 1.0}
                      ${generateRgbArray "on_disabled" [ 0.0 0.0 0.0 ] 0.5}
                      ${generateRgbArray "border" [ 0.96862745 0.87843140 0.38431373 ] 1.0}
                      ${generateRgbArray "disabled_border" [ 0.96862745 0.87843140 0.38431373 ] 0.5}
                    )
                  '';
                };

                ".config/cosmic/com.system76.CosmicTheme.Dark.Builder/v1/accent" = {
                  inherit force;
                  text = generateObject accent false;
                };

                ".config/cosmic/com.system76.CosmicTheme.Mode/v1/auto_switch" = {
                  inherit force;
                  text = if isAuto then "true" else "false";
                };

                ".config/cosmic/com.system76.CosmicTheme.Mode/v1/is_dark" = mkIf (!isAuto) {
                  inherit force;
                  text = if (mode == "dark") then "true" else "false";
                };

                ".config/cosmic/com.system76.CosmicTk/v1/apply_theme_global" = {
                  inherit force;
                  text = if gtkTheming then "true" else "false";
                };
              };
          }) users;
        }
      )
    ];

  meta.name = "theme";
}
