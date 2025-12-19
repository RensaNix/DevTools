{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) concatStringsSep concatMapStringsSep subtractLists mkEnableOption mkOption types mkIf;
  cfg = config.lefthook;

  allHookNames = [
    "applypatch-msg"
    "pre-applypatch"
    "post-applypatch"
    "pre-commit"
    "prepare-commit-msg"
    "commit-msg"
    "post-commit"
    "pre-rebase"
    "post-rewrite"
    "post-checkout"
    "post-merge"
    "pre-push"
    "pre-auto-gc"
    "post-update"
    "sendemail-validate"
    "fsmonitor-watchman"
    "p4-changelist"
    "p4-prepare-changelist"
    "p4-post-changelist"
    "p4-pre-submit"
    "post-index-change"
    "pre-receive"
    "update"
    "proc-receive"
    "reference-transaction"
    "push-to-checkout"
    "pre-merge-commit"
  ];
  currentHookNames = builtins.filter (h: builtins.elem h allHookNames) (builtins.attrNames cfg.config);
  unusedNixHookNames = subtractLists allHookNames currentHookNames;
  unusedNixHookNamesStr = concatStringsSep " " unusedNixHookNames;

  hookContent = hookName:
    pkgs.writeShellScript hookName ''
      if [ "$LEFTHOOK" = "0" ]; then
        exit 0
      fi

      ${lefthookAlias}/bin/${cfg.alias} run "${hookName}" "$@"
    '';

  lefthookConfig = (pkgs.formats.yaml {}).generate "lefthook.yaml" cfg.config;
  lefthookAlias = pkgs.writeShellScriptBin cfg.alias ''
    if [ "$1" = "install" ]; then
      echo "Warning, using 'lefthook install' should not be used, use the shellHook instead"
    fi
    LEFTHOOK_CONFIG="${lefthookConfig}" ${pkgs.lefthook}/bin/lefthook ''${@:1}
  '';
in {
  options.lefthook = {
    enable =
      mkEnableOption "Lefthook"
      // {
        default = cfg.config != {};
      };
    shellHook = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to add a shell hook which automatically installs the git hooks.
      '';
    };
    alias = mkOption {
      type = types.str;
      default = "lefthook";
      example = "hooks";
      description = ''
        Alias for the lefthook command.
      '';
    };
    config = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Config for lefthook. See https://lefthook.dev/configuration/.
      '';
      example = {
        pre-commit = {
          parallel = true;
          jobs = [
            {
              name = "hello";
              run = "echo world";
            }
          ];
        };
      };
    };

    outputs = {
      shellHook = mkOption {
        type = types.str;
        readOnly = true;
        description = ''
          The script to run on shell activation.
          It automatically installs the git hooks and removes unused/previously used ones.
        '';
      };
    };
  };
  config = {
    lefthook.outputs.shellHook =
      # sh
      ''
        ${builtins.readFile ./lefthook_helpers.sh}

        # ensure git is available and we are in a Git repository
        if ! command -v git &> /dev/null; then
          __log ERROR "Git command not found. Cannot manage Git hooks." >&2
          return 1
        fi

        local GIT_REAL_DIR
        GIT_REAL_DIR=$(git rev-parse --git-dir 2>/dev/null)
        if [ $? -ne 0 ]; then
          __log INFO "Not inside a Git repository. Skipping Git hook setup." >&2
          return 0
        fi
        # Use realpath to handle .git file for worktrees, and resolve relative path
        GIT_REAL_DIR=$(realpath "$GIT_REAL_DIR")

        # clean up unused hooks
        cleanup_git_hooks "${unusedNixHookNamesStr}"

        ${concatMapStringsSep "\n" (hook: ''
            setup_git_hook "${hook}" "${hookContent hook}"
          '')
          currentHookNames}
      '';
    packages = mkIf cfg.enable [lefthookAlias];
    enterShellCommands."lefthook" = mkIf (cfg.enable && cfg.shellHook) {
      text = cfg.outputs.shellHook;
      deps = ["env"];
    };
  };
}
