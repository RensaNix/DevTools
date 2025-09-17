{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mapAttrs mkEnableOption mkOption mkIf types;
  cfg = config.task;

  patchedTasks = mapAttrs (_name: value: let
    taskDir = value.dir or "";
    absolutePathOrTemplate = (builtins.substring 0 1 taskDir) == "/" || (builtins.substring 0 1 taskDir) == "{";
  in
    value
    // {
      dir =
        if absolutePathOrTemplate
        then taskDir
        else ''{{env "TASK_ROOT_DIR" | default .USER_WORKING_DIR}}/${taskDir}'';
    })
  cfg.tasks;

  generator = name: value:
    pkgs.writeTextFile {
      inherit name;
      text = builtins.toJSON value;
    };
  # NOTE: this requires python just to convert json to yaml, since json is valid yaml we just ignore that
  # generator = (pkgs.formats.yaml {}).generate;
  taskfile = generator "taskfile" {
    version = 3;
    inherit (cfg) interval;
    tasks = patchedTasks;
  };
  # when using a , as alias for example the store path looks weird.
  # This way it can be identified as being the task alias
  taskAlias = pkgs.writeTextFile {
    name = "task-alias";
    destination = "/bin/${cfg.alias}";
    executable = true;
    text = let
      taskfileScript =
        if cfg.lazy
        then
          # sh
          "$(nix build '${builtins.unsafeDiscardOutputDependency taskfile.drvPath}^*' --no-link --print-out-paths)"
        else taskfile;
    in
      # sh
      ''
        TASKFILE="${taskfileScript}"
        STATE_DIR="''${REN_STATE:-''${DEVENV_STATE:-''${PRJ_CACHE_HOME}}}"
        ROOT_DIR="''${REN_ROOT:-''${DEVENV_ROOT:-''${PRJ_ROOT}}}"

        TASK_TEMP_DIR="''${STATE_DIR}/.task" \
          TASK_ROOT_DIR="$ROOT_DIR" \
          ${pkgs.go-task}/bin/task --taskfile "$TASKFILE" ''${@:1}
      '';
  };
in {
  options.task = {
    enable =
      mkEnableOption "Task"
      // {
        default = cfg.tasks != {};
      };
    lazy = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether the taskfile should be built on-demand/lazily.
        It will probably not land in the gcroot and thus might get cleaned up with every gc.
        On the other hand, this way loading the devshell is faster. Decide for yourself :)
      '';
    };
    alias = mkOption {
      type = types.str;
      default = "task";
      description = ''
        Alias for `task`, eg. set to `,` to be able to run `, --list-all`.
      '';
    };
    interval = mkOption {
      type = types.str;
      default = "5000ms";
      description = ''
        Interval for `task` to check for filesystem changes/watcher updates.
      '';
    };
    tasks = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Configure all your tasks here.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [taskAlias];
  };
}
