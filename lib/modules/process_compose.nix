{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkOption types;
in {
  options.process-compose = mkOption {
    type = types.attrsOf (types.submodule ({
      config,
      name,
      ...
    }: {
      options = {
        alias = mkOption {
          type = types.str;
          default =
            if name == "default"
            then "pc"
            else name;
          description = ''
            Alias for `process-compose`.
            Defaults to `"pc"` if `${name}` is `"default"`
          '';
        };
        lazy = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether the process compose config should be built on-demand/lazily.
            It will probably not land in the gcroot and thus might get cleaned up with every gc.
            On the other hand, this way loading the devshell is faster. Decide for yourself :)
          '';
        };
        config = mkOption {
          type = types.attrs;
          default = {};
          description = ''
            Configure process-compose here.
          '';
        };

        configFile = mkOption {
          internal = true;
          type = types.package;
        };
        pcAlias = mkOption {
          internal = true;
          type = types.package;
        };
      };
      config = rec {
        configFile = (pkgs.formats.yaml {}).generate "process-compose.yaml" config.config;
        pcAlias = pkgs.writeTextFile {
          name = "pc-alias";
          destination = "/bin/${config.alias}";
          executable = true;
          text = let
            configScript =
              if config.lazy
              then
                # sh
                "$(nix build '${builtins.unsafeDiscardOutputDependency configFile.drvPath}^*' --no-link --print-out-paths)"
              else configFile;
          in
            # sh
            ''
              CONFIG_FILE="${configScript}"
              ${pkgs.process-compose}/bin/process-compose --config "$CONFIG_FILE" ''${@:1}
            '';
        };
      };
    }));
    default = {};
    description = ''
      Define your process-compose instances here.
    '';
  };

  config.packages = map (val: val.pcAlias) (builtins.attrValues config.process-compose);
}
