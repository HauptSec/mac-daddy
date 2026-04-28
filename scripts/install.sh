#!/usr/bin/env bash
# mac-daddy — macOS automated setup script
#
# Usage (local):  ./scripts/install.sh [work|personal] [--dry-run] [--verbose] [--skip-macos-defaults]
# Usage (remote): curl -fsSL <raw-url> | bash -s -- [work|personal] [flags]
#
# Flags can appear in any order alongside the profile name.

set -euo pipefail

# ─── Bootstrap: handle curl-pipe execution ────────────────────────────────────
# When piped via curl | bash, BASH_SOURCE[0] is empty or /dev/stdin.
# In that case, clone the repo and re-execute from there.
if [[ -z "${BASH_SOURCE[0]:-}" || "${BASH_SOURCE[0]:-}" == "/dev/stdin" ]]; then
  echo "[mac-daddy] Detected curl-pipe execution. Cloning repo..."
  REPO_CLONE_DIR="${HOME}/.mac-daddy/repo"
  # TODO: Replace with your actual repository URL before publishing
  REPO_URL="https://github.com/HauptSec/mac-daddy"
  if [[ -d "$REPO_CLONE_DIR/.git" ]]; then
    echo "[mac-daddy] Repo already cloned at ${REPO_CLONE_DIR} — pulling latest"
    git -C "$REPO_CLONE_DIR" pull --ff-only
  else
    git clone --depth=1 "$REPO_URL" "$REPO_CLONE_DIR"
  fi
  exec bash "${REPO_CLONE_DIR}/scripts/install.sh" "$@"
fi

# ─── Resolve paths ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ─── Parse arguments ──────────────────────────────────────────────────────────
PROFILE=""
DRY_RUN=false
VERBOSE=false
SKIP_MACOS_DEFAULTS=false

for arg in "$@"; do
  case "$arg" in
    work|personal)         PROFILE="$arg" ;;
    --dry-run)             DRY_RUN=true ;;
    --verbose)             VERBOSE=true ;;
    --skip-macos-defaults) SKIP_MACOS_DEFAULTS=true ;;
    --help|-h)
      printf "Usage: %s [work|personal] [--dry-run] [--verbose] [--skip-macos-defaults]\n" \
        "$(basename "$0")"
      exit 0
      ;;
    *)
      printf "Unknown argument: %s\n" "$arg" >&2
      exit 1
      ;;
  esac
done

export DRY_RUN VERBOSE SKIP_MACOS_DEFAULTS

# ─── Set up log file ──────────────────────────────────────────────────────────
MAC_DADDY_DIR="${HOME}/.mac-daddy"
mkdir -p "${MAC_DADDY_DIR}/logs"
LOG_FILE="${MAC_DADDY_DIR}/logs/install-$(date +%Y%m%d-%H%M%S).log"
export LOG_FILE
touch "$LOG_FILE"

# ─── Source libraries ─────────────────────────────────────────────────────────
# shellcheck source=scripts/lib/utils.sh
source "${SCRIPT_DIR}/lib/utils.sh"
# shellcheck source=scripts/lib/brew.sh
source "${SCRIPT_DIR}/lib/brew.sh"
# shellcheck source=scripts/lib/direct.sh
source "${SCRIPT_DIR}/lib/direct.sh"
# shellcheck source=scripts/lib/dotfiles.sh
source "${SCRIPT_DIR}/lib/dotfiles.sh"
# shellcheck source=scripts/lib/macos.sh
source "${SCRIPT_DIR}/lib/macos.sh"

# ─── Summary tracking ─────────────────────────────────────────────────────────
INSTALL_SUMMARY=()
INSTALL_ERRORS=()

record_ok()   { INSTALL_SUMMARY+=("${GREEN}✓${RESET} $*"); }
record_skip() { INSTALL_SUMMARY+=("${YELLOW}⊘${RESET} $*"); }
record_fail() { INSTALL_ERRORS+=("${RED}✗${RESET} $*"); }

# ─── Profile menu ─────────────────────────────────────────────────────────────
choose_profile() {
  printf "\n${BLUE}${BOLD}┌─────────────────────────────────────┐\n"
  printf "│           mac-daddy setup           │\n"
  printf "└─────────────────────────────────────┘${RESET}\n\n"
  printf "Select a profile:\n\n"
  printf "  ${BOLD}1)${RESET} work      — dev tools, Slack, Zoom, work git config\n"
  printf "  ${BOLD}2)${RESET} personal  — personal apps, Spotify, Discord\n\n"
  printf "Choice [1/2]: "
  local choice
  read -r choice
  case "$choice" in
    1|work)     echo "work" ;;
    2|personal) echo "personal" ;;
    *)
      printf "Invalid choice: %s\n" "$choice" >&2
      exit 1
      ;;
  esac
}

# ─── Preflight checks ─────────────────────────────────────────────────────────
run_preflight() {
  log_section "Preflight Checks"

  # Skip macOS-specific checks when running in CI dry-run on Linux
  if [[ "$(uname -s)" != "Darwin" ]]; then
    if is_dry_run; then
      log_warn "Non-macOS system detected — skipping system preflight (dry-run/CI mode)"
      return 0
    else
      log_error "This script requires macOS."
      exit 1
    fi
  fi

  require_min_version 13 0
  log_success "macOS version: OK ($(sw_vers -productVersion))"

  log_info "Checking internet connectivity..."
  if ! curl -fsSL --max-time 10 --head https://formulae.brew.sh &>/dev/null; then
    log_error "No internet connectivity. Check your connection and retry."
    exit 1
  fi
  log_success "Internet: OK"

  log_info "Checking Xcode Command Line Tools..."
  if ! xcode-select -p &>/dev/null; then
    log_warn "Xcode CLT not found. Launching installer..."
    xcode-select --install 2>/dev/null || true
    log_error "Xcode CLT installation required. Re-run this script after it completes."
    exit 1
  fi
  log_success "Xcode CLT: OK"
}

# ─── Oh My Zsh + custom plugins ───────────────────────────────────────────────
install_oh_my_zsh() {
  log_section "Oh My Zsh"

  if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    log_warn "Oh My Zsh already installed — skipping"
    record_skip "Oh My Zsh"
    return 0
  fi

  log_info "Installing Oh My Zsh (non-interactive)..."
  # RUNZSH=no prevents forking a new shell; CHSH=no skips changing default shell
  # Guard is_dry_run explicitly: the $() subshell would fetch the script even
  # inside run_or_dry because argument expansion happens before the call.
  if is_dry_run; then
    log_info "[DRY-RUN] env RUNZSH=no CHSH=no sh -c \$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    env RUNZSH=no CHSH=no sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
  record_ok "Oh My Zsh"
}

install_zsh_plugins() {
  log_section "Zsh Plugins"

  local custom_dir="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins"

  if is_dry_run; then
    log_info "[DRY-RUN] Would clone zsh-autosuggestions and zsh-syntax-highlighting"
    return 0
  fi

  if [[ ! -d "${custom_dir}/zsh-autosuggestions" ]]; then
    log_info "Installing zsh-autosuggestions..."
    run_or_dry git clone --depth=1 \
      https://github.com/zsh-users/zsh-autosuggestions \
      "${custom_dir}/zsh-autosuggestions"
    log_success "  installed: zsh-autosuggestions"
  else
    log_warn "  skip: zsh-autosuggestions"
  fi

  if [[ ! -d "${custom_dir}/zsh-syntax-highlighting" ]]; then
    log_info "Installing zsh-syntax-highlighting..."
    run_or_dry git clone --depth=1 \
      https://github.com/zsh-users/zsh-syntax-highlighting \
      "${custom_dir}/zsh-syntax-highlighting"
    log_success "  installed: zsh-syntax-highlighting"
  else
    log_warn "  skip: zsh-syntax-highlighting"
  fi

  record_ok "Zsh plugins"
}

# ─── Summary report ───────────────────────────────────────────────────────────
print_summary() {
  log_section "Installation Summary"

  printf "${BOLD}Completed:${RESET}\n"
  if [[ ${#INSTALL_SUMMARY[@]} -gt 0 ]]; then
    local item
    for item in "${INSTALL_SUMMARY[@]}"; do
      printf "  %b\n" "$item"
    done
  fi

  if [[ ${#INSTALL_ERRORS[@]} -gt 0 ]]; then
    printf "\n${BOLD}Errors:${RESET}\n"
    local err
    for err in "${INSTALL_ERRORS[@]}"; do
      printf "  %b\n" "$err"
    done
  fi

  printf "\n${CYAN}Log: %s${RESET}\n\n" "$LOG_FILE"

  if [[ ${#INSTALL_ERRORS[@]} -gt 0 ]]; then
    log_warn "Setup completed with errors. Review the log above."
    return 1
  fi
  log_success "mac-daddy setup complete! Open a new terminal to load your config."
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  if [[ ! -d "${REPO_ROOT}/profiles" ]]; then
    printf "ERROR: Cannot locate repo profiles directory at %s\n" "${REPO_ROOT}/profiles" >&2
    printf "Clone the repo and run: ./scripts/install.sh\n" >&2
    exit 1
  fi

  if [[ -z "$PROFILE" ]]; then
    PROFILE="$(choose_profile)"
  fi

  if [[ "$PROFILE" != "work" && "$PROFILE" != "personal" ]]; then
    log_error "Unknown profile '${PROFILE}'. Choose 'work' or 'personal'."
    exit 1
  fi

  printf "\n${BOLD}mac-daddy${RESET}  profile=${BOLD}%s${RESET}" "$PROFILE"
  if is_dry_run; then
    printf "  ${YELLOW}[DRY RUN — no changes will be made]${RESET}"
  fi
  printf "\n"

  local shared="${REPO_ROOT}/profiles/shared"
  local profile="${REPO_ROOT}/profiles/${PROFILE}"

  # 1. Preflight
  run_preflight
  record_ok "Preflight checks"

  # 2. Homebrew
  log_section "Homebrew"
  install_homebrew
  record_ok "Homebrew"

  # 3. Oh My Zsh
  install_oh_my_zsh
  install_zsh_plugins

  # 4. Shared formulae
  log_section "Shared Homebrew Formulae"
  install_formulae "${shared}/apps/brew-formulae.txt"
  record_ok "Shared formulae"

  # 5. Shared casks
  log_section "Shared Homebrew Casks"
  install_casks "${shared}/apps/brew-casks.txt"
  record_ok "Shared casks"

  # 6. Profile formulae
  log_section "${PROFILE} Homebrew Formulae"
  install_formulae "${profile}/apps/brew-formulae.txt"
  record_ok "${PROFILE} formulae"

  # 7. Profile casks
  log_section "${PROFILE} Homebrew Casks"
  install_casks "${profile}/apps/brew-casks.txt"
  record_ok "${PROFILE} casks"

  # 8. Shared direct downloads
  log_section "Shared Direct Downloads"
  install_direct_downloads "${shared}/apps/direct-downloads.yaml"
  record_ok "Shared direct downloads"

  # 9. Profile direct downloads
  log_section "${PROFILE} Direct Downloads"
  install_direct_downloads "${profile}/apps/direct-downloads.yaml"
  record_ok "${PROFILE} direct downloads"

  # 10. Shared dotfiles
  log_section "Shared Dotfiles"
  apply_dotfiles "${shared}/dotfiles"
  record_ok "Shared dotfiles"

  # 11. Profile dotfiles
  log_section "${PROFILE} Dotfiles"
  apply_dotfiles "${profile}/dotfiles"
  record_ok "${PROFILE} dotfiles"

  # 12. Shared macOS defaults
  log_section "Shared macOS Defaults"
  apply_macos_defaults "${shared}/macos/defaults.sh"
  record_ok "Shared macOS defaults"

  # 13. Profile macOS defaults
  log_section "${PROFILE} macOS Defaults"
  apply_macos_defaults "${profile}/macos/defaults.sh"
  record_ok "${PROFILE} macOS defaults"

  # 14. Cleanup
  log_section "Cleanup"
  if command_exists brew; then
    log_info "Running brew cleanup..."
    run_or_dry brew cleanup
  fi
  record_ok "Cleanup"

  # 15. Summary
  print_summary
}

main "$@"
