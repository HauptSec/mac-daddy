#!/usr/bin/env bash
# macOS system preferences application.
# Sourced by install.sh — do NOT add set -euo pipefail here.

# Sources a defaults.sh file and restarts affected system processes.
# No-ops when --skip-macos-defaults is active or when not on macOS.
# Enables Touch ID for sudo via /etc/pam.d/sudo_local (Sonoma+ approach).
# Also adds pam_reattach so Touch ID works inside tmux.
# Idempotent: checks each line independently before adding.
# pam_reattach must appear before pam_tid.so in the file.
enable_touch_id_sudo() {
  if [[ "$SKIP_MACOS_DEFAULTS" == "true" ]]; then
    log_warn "Skipping Touch ID sudo (--skip-macos-defaults)"
    return 0
  fi

  if [[ "$(uname -s)" != "Darwin" ]]; then
    log_warn "Skipping Touch ID sudo (not on macOS)"
    return 0
  fi

  local pam_local="/etc/pam.d/sudo_local"
  local pam_template="/etc/pam.d/sudo_local.template"
  local reattach_line="auth       optional       /opt/homebrew/lib/pam/pam_reattach.so"
  local tid_line="auth       sufficient     pam_tid.so"

  local needs_reattach=false needs_tid=false
  grep -q "pam_reattach.so" "${pam_local}" 2>/dev/null || needs_reattach=true
  grep -q "pam_tid.so"      "${pam_local}" 2>/dev/null || needs_tid=true

  if [[ "$needs_reattach" == "false" && "$needs_tid" == "false" ]]; then
    log_info "Touch ID for sudo already enabled."
    return 0
  fi

  log_info "Enabling Touch ID for sudo..."

  if is_dry_run; then
    log_info "[DRY-RUN] Would configure ${pam_local} with pam_reattach + pam_tid"
    return 0
  fi

  # Create file if missing
  if [[ ! -f "${pam_local}" ]]; then
    if [[ -f "${pam_template}" ]]; then
      sudo cp "${pam_template}" "${pam_local}"
    else
      printf "# sudo_local: local config file which survives system update and is included for sudo\n" \
        | sudo tee "${pam_local}" > /dev/null
    fi
  fi

  # Handle pam_tid.so first (uncomment or append)
  if [[ "$needs_tid" == "true" ]]; then
    if grep -q "^#.*pam_tid\.so" "${pam_local}"; then
      sudo sed -i '' "s|^#.*pam_tid\.so|${tid_line}|" "${pam_local}"
    else
      printf "%s\n" "${tid_line}" | sudo tee -a "${pam_local}" > /dev/null
    fi
  fi

  # Insert pam_reattach before pam_tid.so line (must come first for tmux support)
  if [[ "$needs_reattach" == "true" ]]; then
    sudo sed -i '' "s|.*pam_tid\.so|${reattach_line}\\
&|" "${pam_local}"
  fi

  log_success "Touch ID for sudo enabled (pam_reattach + pam_tid)."
}

# Points iTerm2 at the repo's iterm2/ directory so it reads and writes
# preferences there directly — no copy needed, changes stay in git.
configure_iterm2_prefs() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    log_warn "Skipping iTerm2 prefs (not on macOS)"
    return 0
  fi

  local iterm2_prefs_dir
  iterm2_prefs_dir="$(cd "${REPO_ROOT}/profiles/shared/iterm2" && pwd)"

  if [[ ! -d "${iterm2_prefs_dir}" ]]; then
    log_warn "iTerm2 prefs dir not found: ${iterm2_prefs_dir}"
    return 0
  fi

  local current_folder
  current_folder="$(defaults read com.googlecode.iterm2 PrefsCustomFolder 2>/dev/null || true)"

  if [[ "${current_folder}" == "${iterm2_prefs_dir}" ]]; then
    log_info "iTerm2 already pointing at repo prefs."
    return 0
  fi

  if is_dry_run; then
    log_info "[DRY-RUN] Would set iTerm2 PrefsCustomFolder to: ${iterm2_prefs_dir}"
    return 0
  fi

  defaults write com.googlecode.iterm2 PrefsCustomFolder -string "${iterm2_prefs_dir}"
  defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

  log_success "iTerm2 preferences pointed at: ${iterm2_prefs_dir}"
}

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
