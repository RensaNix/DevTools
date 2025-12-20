{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types assertMsg versionAtLeast;
  cfg = config.cocogitto;

  configFile = (pkgs.formats.toml {}).generate "cog.toml" cfg.config;
  cogAlias = assert assertMsg (versionAtLeast pkgs.cocogitto.version "6.4")
  "cocogitto needs to be version 6.4 or higher to support the --config param";
    pkgs.writeTextFile {
      name = "cog-alias";
      destination = "/bin/${cfg.alias}";
      executable = true;
      text =
        # sh
        ''
          ${pkgs.cocogitto}/bin/cog --config "${configFile}" ''${@:1}
        '';
    };
in {
  options.cocogitto = {
    enable =
      mkEnableOption "Cocogitto"
      // {
        default = cfg.config != {};
      };
    alias = mkOption {
      type = types.str;
      default = "cog";
      description = ''
        Alias for `cog`.
      '';
    };
    config = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Configure cocogitto here.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cogAlias];
  };
}
