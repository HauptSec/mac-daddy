#!/usr/bin/env bash
# Shared utility functions — sourced by install.sh and other lib files.
# Do NOT add set -euo pipefail here; this file is sourced, not executed.

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Global flags (exported by install.sh before sourcing) ────────────────────
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
SKIP_MACOS_DEFAULTS="${SKIP_MACOS_DEFAULTS:-false}"
LOG_FILE="${LOG_FILE:-}"

# ─── Logging ──────────────────────────────────────────────────────────────────

# Internal: write colored line to stdout and optionally to log file
_log() {
  local color="$1"
  local prefix="$2"
  shift 2
  local msg="$*"
  printf "${color}%s %s${RESET}\n" "$prefix" "$msg"
  if [[ -n "$LOG_FILE" ]]; then
    printf "%s %s\n" "$prefix" "$msg" >> "$LOG_FILE"
  fi
}

log_info()    { _log "$CYAN"   "[INFO]  " "$*"; }
log_success() { _log "$GREEN"  "[OK]    " "$*"; }
log_warn()    { _log "$YELLOW" "[WARN]  " "$*"; }
log_error()   { _log "$RED"    "[ERROR] " "$*"; }

# Prints a prominent section header banner
log_section() {
  local msg="$*"
  local line="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "\n${BLUE}${BOLD}%s\n  %s\n%s${RESET}\n\n" "$line" "$msg" "$line"
  if [[ -n "$LOG_FILE" ]]; then
    printf "\n%s\n  %s\n%s\n\n" "$line" "$msg" "$line" >> "$LOG_FILE"
  fi
}

# ─── Predicates ───────────────────────────────────────────────────────────────

# Returns 0 if the given command exists in PATH
command_exists() {
  command -v "$1" &>/dev/null
}

# Returns 0 if a .app bundle exists in /Applications or ~/Applications
app_exists() {
  local app_name="$1"
  [[ -d "/Applications/${app_name}" ]] || [[ -d "${HOME}/Applications/${app_name}" ]]
}

# Returns 0 if dry-run mode is active
is_dry_run() {
  [[ "$DRY_RUN" == "true" ]]
}

# ─── Interactive ──────────────────────────────────────────────────────────────

# Prompts user with a y/n question; second arg sets default (y or n)
confirm() {
  local message="$1"
  local default="${2:-y}"
  local prompt
  if [[ "$default" == "y" ]]; then
    prompt="[Y/n]"
  else
    prompt="[y/N]"
  fi
  printf "${YELLOW}%s %s ${RESET}" "$message" "$prompt"
  read -r answer
  answer="${answer:-$default}"
  [[ "${answer,,}" == "y" ]]
}

# ─── System guards ────────────────────────────────────────────────────────────

# Exits with error if not running on macOS
require_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    log_error "This script requires macOS."
    exit 1
  fi
}

# Exits if current macOS version is below major.minor
require_min_version() {
  local required_major="$1"
  local required_minor="$2"
  local os_version
  os_version="$(sw_vers -productVersion)"
  local current_major current_minor
  current_major="$(echo "$os_version" | cut -d. -f1)"
  current_minor="$(echo "$os_version" | cut -d. -f2)"
  if (( current_major < required_major )) || \
     (( current_major == required_major && current_minor < required_minor )); then
    log_error "Requires macOS ${required_major}.${required_minor}+. Current: ${os_version}"
    exit 1
  fi
}

# ─── Execution ────────────────────────────────────────────────────────────────

# Executes a command, or prints it if dry-run is active
run_or_dry() {
  if is_dry_run; then
    log_info "[DRY-RUN] $*"
  else
    if [[ "$VERBOSE" == "true" ]]; then
      log_info "Running: $*"
    fi
    "$@"
  fi
}
