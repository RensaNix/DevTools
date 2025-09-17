# Usage: __log <LEVEL> "message"
# LEVEL can be: TRACE, INFO, WARN, ERROR
__log() {
  local level="$1" msg="$2"
  local format=$'\E[mlefthook: \E[38;5;8m%s\E[m\n'
  case "$level" in
  TRACE)
    if [[ -n "${LEFTHOOK_VERBOSE:-}" ]]; then
      # shellcheck disable=SC2059
      printf "$format" "[TRACE] ${msg}" >&2
    fi
    ;;
  INFO)
    if [[ -n "${LEFTHOOK_VERBOSE:-}" ]]; then
      # shellcheck disable=SC2059
      printf "$format" "$msg" >&2
    fi
    ;;
  WARN)
    # shellcheck disable=SC2059
    printf "$format" "[WARN] ${msg}" >&2
    ;;
  ERROR)
    # shellcheck disable=SC2059
    printf "$format" "[ERROR] ${msg}" >&2
    ;;
  esac
}

# Helper to get the current Git hooks directory, supporting worktrees.
# Returns the absolute path to the hooks directory.
_get_git_hooks_dir() {
  # Check if we are inside a Git repository
  if ! command -v git &> /dev/null; then
    __log ERROR "Git command not found. Cannot resolve Git hooks directory."
    return 1
  fi
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    __log ERROR "Not inside a Git repository. Cannot resolve Git hooks directory."
    return 1
  fi
  local GIT_DIR_PATH
  GIT_DIR_PATH=$(git rev-parse --git-dir)
  GIT_DIR_PATH=$(realpath "$GIT_DIR_PATH") # Resolve to absolute path
  echo "${GIT_DIR_PATH}/hooks"
  return 0
}

# Function to set up a Git hook as a symlink to a Nix store path.
# Usage: setup_git_hook <hook_name> <nix_store_hook_path>
setup_git_hook() {
  local HOOK_NAME="$1"
  local NIX_HOOK_PATH="$2"
  local NIX_STORE_PATTERN="/nix/store/" # Pattern to identify Nix store paths

  local HOOK_DIR
  HOOK_DIR=$(_get_git_hooks_dir)
  if [ $? -ne 0 ]; then
    return 1 # Error from _get_git_hooks_dir
  fi

  local HOOK_FILE="${HOOK_DIR}/${HOOK_NAME}"
  local BACKUP_FILE="${HOOK_FILE}.old"

  # Ensure the hooks directory exists
  mkdir -p "$HOOK_DIR"

  if [ -e "$HOOK_FILE" ]; then # Check if anything exists at the hook path
    if [ -L "$HOOK_FILE" ]; then # Existing hook is a symlink
      local CURRENT_TARGET
      CURRENT_TARGET=$(readlink "$HOOK_FILE")

      if [[ "$CURRENT_TARGET" == "$NIX_HOOK_PATH" ]]; then
        __log TRACE "Hook '$HOOK_NAME' already exists and points to the correct Nix store path. Doing nothing."
        return 0
      elif [[ "$CURRENT_TARGET" == $NIX_STORE_PATTERN* ]]; then
        __log TRACE "Hook '$HOOK_NAME' is a symlink to a different Nix store path. Replacing it with the new symlink."
        rm "$HOOK_FILE"
      else
        __log INFO "Hook '$HOOK_NAME' is a symlink but not to a Nix store path. Backing up to '$BACKUP_FILE'."
        mv "$HOOK_FILE" "$BACKUP_FILE"
      fi
    elif [ -f "$HOOK_FILE" ]; then # Existing hook is a regular file
      # Assumption: any non-symlink hook file is not ours
      __log INFO "Hook '$HOOK_NAME' is an existing regular file (not managed by us). Backing up to '$BACKUP_FILE'."
      mv "$HOOK_FILE" "$BACKUP_FILE"
    else # Existing hook is neither a symlink nor a regular file (e.g., directory)
      __log WARN "Hook '$HOOK_NAME' exists but is not a regular file or symlink. Please check your hooks and remove the hook manually just in case."
      exit 1
    fi
  fi

  __log INFO "Creating symlink for '$HOOK_NAME' to '$NIX_HOOK_PATH'."
  ln -s "$NIX_HOOK_PATH" "$HOOK_FILE"
}

# Function to clean up specific Git hooks that are no longer used by Nix.
# It removes symlinks that point to the Nix store for the given hook names
# and restores any .old backups if they exist.
# Usage: cleanup_git_hooks <space-separated-list-of-unused-hook-names>
cleanup_git_hooks() {
  local UNUSED_HOOK_NAMES_STR="$1"
  local NIX_STORE_PATTERN="/nix/store/"

  if [ -z "$UNUSED_HOOK_NAMES_STR" ]; then
    __log TRACE "No unused hooks specified for cleanup. Doing nothing."
    return 0
  fi

  local HOOK_DIR
  HOOK_DIR=$(_get_git_hooks_dir)
  if [ $? -ne 0 ]; then
    return 1 # Error from _get_git_hooks_dir
  fi

  if [ ! -d "$HOOK_DIR" ]; then
    __log TRACE "No hooks directory found at '$HOOK_DIR'. Nothing to clean up."
    return 0
  fi

  __log TRACE "Cleaning up unused Git hooks in '$HOOK_DIR'..."
  for HOOK_NAME in $UNUSED_HOOK_NAMES_STR; do
    local HOOK_FILE_PATH="${HOOK_DIR}/${HOOK_NAME}"

    if [ -L "$HOOK_FILE_PATH" ]; then # Only consider symlinks
      local TARGET
      TARGET=$(readlink "$HOOK_FILE_PATH")

      # Check if the symlink points to a Nix store path
      if [[ "$TARGET" == $NIX_STORE_PATTERN* ]]; then
        __log INFO "Removing unused Nix-managed hook: '$HOOK_NAME' (points to '$TARGET')"
        rm "$HOOK_FILE_PATH"

        # Check for a corresponding .old file and restore it if it exists
        local OLD_HOOK="${HOOK_FILE_PATH}.old"
        if [ -e "$OLD_HOOK" ]; then
          __log INFO "Restoring backup: '$OLD_HOOK' to '${HOOK_FILE_PATH}'"
          mv "$OLD_HOOK" "$HOOK_FILE_PATH"
        fi
      else
        __log TRACE "Hook '$HOOK_NAME' is a symlink but not to a Nix store path. Skipping cleanup (it's not our managed symlink)."
      fi
    elif [ -e "$HOOK_FILE_PATH" ]; then
      __log TRACE "Hook '$HOOK_NAME' exists but is not a symlink (not managed by us). Skipping cleanup."
    else
      __log TRACE "Hook '$HOOK_NAME' does not exist. Skipping cleanup."
    fi
  done
}
