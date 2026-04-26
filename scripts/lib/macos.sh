#!/usr/bin/env bash
# macOS system preferences application.
# Sourced by install.sh — do NOT add set -euo pipefail here.

# Sources a defaults.sh file and restarts affected system processes.
# No-ops when --skip-macos-defaults is active or when not on macOS.
apply_macos_defaults() {
  local defaults_file="$1"

  if [[ "$SKIP_MACOS_DEFAULTS" == "true" ]]; then
    log_warn "Skipping macOS defaults (--skip-macos-defaults)"
    return 0
  fi

  if [[ "$(uname -s)" != "Darwin" ]]; then
    log_warn "Skipping macOS defaults (not on macOS)"
    return 0
  fi

  if [[ ! -f "$defaults_file" ]]; then
    log_warn "Defaults file not found: $defaults_file"
    return 0
  fi

  log_info "Applying: $(basename "$defaults_file")"

  if is_dry_run; then
    log_info "[DRY-RUN] Would source: $defaults_file"
    return 0
  fi

  # shellcheck source=/dev/null
  source "$defaults_file"
  log_success "Defaults applied."

  log_info "Restarting affected system processes..."
  local proc
  for proc in Dock Finder SystemUIServer cfprefsd; do
    if pgrep -x "$proc" &>/dev/null; then
      killall "$proc" 2>/dev/null || true
    fi
  done
}
