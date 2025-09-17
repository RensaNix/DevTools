{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.cocogitto;

  # we need a newer version than in nixpkgs, since the PR which adds `--config`
  # didn't land in a release yet
  cocogitto = pkgs.cocogitto.overrideAttrs (_prev: {
    version = "2025-09-11";
    src = pkgs.fetchFromGitHub {
      owner = "oknozor";
      repo = "cocogitto";
      rev = "031cc238cb3e3e8aa3a525c1df089c3e70020efc";
      hash = "sha256-fyhugacBLJPMqHWxoxBTFhIE3wHDB9xdrqJYzJc36I0=";
    };
  });

  configFile = (pkgs.formats.toml {}).generate "cog.toml" cfg.config;
  cogAlias = pkgs.writeTextFile {
    name = "cog-alias";
    destination = "/bin/${cfg.alias}";
    executable = true;
    text =
      # sh
      ''
        ${cocogitto}/bin/cog --config "${configFile}" ''${@:1}
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
