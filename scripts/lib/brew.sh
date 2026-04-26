#!/usr/bin/env bash
# Homebrew installation and package management.
# Sourced by install.sh — do NOT add set -euo pipefail here.

# Returns the expected Homebrew prefix for the current CPU architecture
get_brew_prefix() {
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo "/opt/homebrew"
  else
    echo "/usr/local"
  fi
}

# Installs Homebrew if missing; runs brew update if already present
install_homebrew() {
  if command_exists brew; then
    log_info "Homebrew already installed — updating"
    run_or_dry brew update
    return 0
  fi

  log_info "Installing Homebrew..."
  # The official installer requires sudo internally for /opt/homebrew or /usr/local setup
  run_or_dry /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Activate brew in current shell session after install
  local brew_prefix
  brew_prefix="$(get_brew_prefix)"
  if [[ -x "${brew_prefix}/bin/brew" ]]; then
    eval "$("${brew_prefix}/bin/brew" shellenv)"
  fi
}

# Reads a .txt formula list and installs only formulae not already present.
# File format: one formula per line; lines starting with # are comments.
install_formulae() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    log_warn "Formulae file not found: $file"
    return 0
  fi

  if ! command_exists brew; then
    log_warn "Homebrew not found — skipping formula install from: $file"
    return 0
  fi

  log_info "Building installed formulae index..."
  local installed_formulae
  installed_formulae="$(brew list --formula 2>/dev/null || true)"

  local installed_count=0 skipped_count=0 failed_count=0

  while IFS= read -r raw; do
    # Strip inline comments and surrounding whitespace
    local formula="${raw%%#*}"
    formula="${formula//[[:space:]]/}"
    [[ -z "$formula" ]] && continue

    if echo "$installed_formulae" | grep -qx "$formula"; then
      log_warn "  skip: $formula"
      (( skipped_count++ )) || true
    else
      log_info "  installing: $formula"
      if run_or_dry brew install "$formula"; then
        log_success "  installed: $formula"
        (( installed_count++ )) || true
      else
        log_error "  failed: $formula"
        (( failed_count++ )) || true
      fi
    fi
  done < "$file"

  log_info "Formulae — installed: ${installed_count}, skipped: ${skipped_count}, failed: ${failed_count}"
}

# Reads a .txt cask list and installs only casks not already present.
# Checks /Applications before installing to handle non-brew-managed apps.
install_casks() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    log_warn "Casks file not found: $file"
    return 0
  fi

  if ! command_exists brew; then
    log_warn "Homebrew not found — skipping cask install from: $file"
    return 0
  fi

  log_info "Building installed casks index..."
  local installed_casks
  installed_casks="$(brew list --cask 2>/dev/null || true)"

  local installed_count=0 skipped_count=0 failed_count=0

  while IFS= read -r raw; do
    # Strip inline comments and surrounding whitespace
    local cask="${raw%%#*}"
    cask="${cask//[[:space:]]/}"
    [[ -z "$cask" ]] && continue

    if echo "$installed_casks" | grep -qx "$cask"; then
      log_warn "  skip (brew): $cask"
      (( skipped_count++ )) || true
      continue
    fi

    # Heuristic: look for a matching .app in /Applications to catch non-brew installs
    local app_pattern="${cask//-/ }"
    if find /Applications -maxdepth 1 -iname "*.app" 2>/dev/null \
       | grep -qi "$app_pattern" 2>/dev/null; then
      log_warn "  skip (found in /Applications, not managed by brew): $cask"
      (( skipped_count++ )) || true
      continue
    fi

    log_info "  installing: $cask"
    if run_or_dry brew install --cask "$cask"; then
      log_success "  installed: $cask"
      (( installed_count++ )) || true
    else
      log_error "  failed: $cask"
      (( failed_count++ )) || true
    fi
  done < "$file"

  log_info "Casks — installed: ${installed_count}, skipped: ${skipped_count}, failed: ${failed_count}"
}
