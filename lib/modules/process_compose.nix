{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.process-compose;

  configFile = (pkgs.formats.yaml {}).generate "process-compose.yaml" cfg.config;
  pcAlias = pkgs.writeTextFile {
    name = "pc-alias";
    destination = "/bin/${cfg.alias}";
    executable = true;
    text =
      # sh
      ''
        ${pkgs.process-compose}/bin/process-compose --config "${configFile}" ''${@:1}
      '';
  };
in {
  options.process-compose = {
    enable =
      mkEnableOption "Process-Compose"
      // {
        default = cfg.config != {};
      };
    alias = mkOption {
      type = types.str;
      default = "pc";
      description = ''
        Alias for `process-compose`.
      '';
    };
    config = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Configure process-compose here.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [pcAlias];
  };
}
