{ config, lib, pkgs, ... }:

with lib;
let
  iconDir = pkgs.runCommand "icons" { preferLocalBuild = true; } ''
    mkdir -p "$out"
    ${concatMapStrings (p: ''
        if [ -d "${p}/share/icons" ]; then
            find -L "${p}/share/icons" -mindepth 1 -maxdepth 1 -type d -exec cp -rn --no-preserve=mode,ownership {}/ "$out" \;
        fi
    '') config.environment.icons}
  '';
in {
  options = {
    environment = {
      icons = mkOption {
        type = types.listOf types.package;
        default = [];
        example = literalExpression "[ pkgs.papirus-icon-theme pkgs.breeze-icons ]";
        description = ''
          The set of packages that appear in
          /usr/share/icons. These packages are
          automatically available to all users, and are
          automatically updated every time you rebuild the system
          configuration.
        '';
      };
    };
  };

  config = mkIf (config.environment.icons != []) {
      fileSystems."/usr/share/icons" = {
        device = "${iconDir}";
        fsType = "none";
        options = [ "bind" ];
      };
      environment.sessionVariables.XDG_DATA_DIRS = [ "/usr/share" ];
  };
}
