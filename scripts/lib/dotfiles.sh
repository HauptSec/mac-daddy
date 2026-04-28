#!/usr/bin/env bash
# Dotfile symlink management.
# Sourced by install.sh — do NOT add set -euo pipefail here.

DOTFILES_BACKUP_DIR="${HOME}/.mac-daddy/backups/dotfiles"

# Creates $HOME symlinks for every file in the given flat directory.
# Conflict resolution:
#   - Already symlinked to correct path → skip
#   - Symlink pointing elsewhere → re-link
#   - Regular file → back up with timestamp, then symlink
#   - Missing → symlink directly
apply_dotfiles() {
  local dotfiles_dir="$1"

  if [[ ! -d "$dotfiles_dir" ]]; then
    log_warn "Dotfiles directory not found: $dotfiles_dir"
    return 0
  fi

  local linked=0 skipped=0 backed_up=0

  # -maxdepth 1 ensures no subdirectory recursion; -print0 handles filenames with spaces
  while IFS= read -r -d '' src_file; do
    local filename
    filename="$(basename "$src_file")"
    local target="${HOME}/${filename}"

    if [[ -L "$target" ]]; then
      local existing_link
      existing_link="$(readlink "$target")"
      if [[ "$existing_link" == "$src_file" ]]; then
        log_warn "  skip (already linked): ${filename}"
        (( skipped++ )) || true
        continue
      else
        log_warn "  re-linking (was pointing to ${existing_link}): ${filename}"
        run_or_dry rm "$target"
      fi
    elif [[ -e "$target" ]]; then
      run_or_dry mkdir -p "$DOTFILES_BACKUP_DIR"
      local ts
      ts="$(date +%Y%m%d-%H%M%S)"
      local backup="${DOTFILES_BACKUP_DIR}/${filename}.${ts}.bak"
      log_warn "  backing up: ${filename} → ${backup}"
      run_or_dry mv "$target" "$backup"
      (( backed_up++ )) || true
    fi

    log_info "  linking: ${filename}"
    run_or_dry ln -sf "$src_file" "$target"
    log_success "  linked: ${filename} → ${src_file}"
    (( linked++ )) || true
  done < <(find "$dotfiles_dir" -maxdepth 1 -type f -print0)

  log_info "Dotfiles — linked: ${linked}, skipped: ${skipped}, backed up: ${backed_up}"
}

# Symlinks VS Code settings files from profiles/shared/vscode/ into the
# correct VS Code user config directory (macOS only).
link_vscode_settings() {
  local vscode_src_dir="$1"
  local vscode_config_dir="${HOME}/Library/Application Support/Code/User"

  if [[ "$(uname -s)" != "Darwin" ]]; then
    log_warn "Skipping VS Code settings (not on macOS)"
    return 0
  fi

  if [[ ! -d "${vscode_src_dir}" ]]; then
    log_warn "VS Code settings dir not found: ${vscode_src_dir}"
    return 0
  fi

  if is_dry_run; then
    log_info "[DRY-RUN] Would symlink VS Code settings into: ${vscode_config_dir}"
    return 0
  fi

  mkdir -p "${vscode_config_dir}"

  while IFS= read -r -d '' src_file; do
    local filename
    filename="$(basename "${src_file}")"
    local target="${vscode_config_dir}/${filename}"

    if [[ -L "${target}" ]]; then
      local existing_link
      existing_link="$(readlink "${target}")"
      if [[ "${existing_link}" == "${src_file}" ]]; then
        log_warn "  skip (already linked): ${filename}"
        continue
      else
        log_warn "  re-linking (was pointing to ${existing_link}): ${filename}"
        rm "${target}"
      fi
    elif [[ -e "${target}" ]]; then
      mkdir -p "${DOTFILES_BACKUP_DIR}"
      local ts
      ts="$(date +%Y%m%d-%H%M%S)"
      local backup="${DOTFILES_BACKUP_DIR}/vscode-${filename}.${ts}.bak"
      log_warn "  backing up: ${filename} → ${backup}"
      mv "${target}" "${backup}"
    fi

    ln -sf "${src_file}" "${target}"
    log_success "  linked: ${filename} → ${src_file}"
  done < <(find "${vscode_src_dir}" -maxdepth 1 -type f -print0)
}
