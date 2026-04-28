#!/usr/bin/env bash
# Validates the mac-daddy repo structure, file formats, and basic security checks.
# Exit 0 on success; non-zero with descriptive errors on failure.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

ERRORS=0
WARNINGS=0

pass() { printf "${GREEN}  [PASS]${RESET} %s\n" "$*"; }
warn() { printf "${YELLOW}  [WARN]${RESET} %s\n" "$*"; (( WARNINGS++ )) || true; }
fail() { printf "${RED}  [FAIL]${RESET} %s\n" "$*" >&2; (( ERRORS++ )) || true; }

section() {
  printf "\n${BLUE}${BOLD}── %s ──${RESET}\n" "$*"
}

# ─── Required file/directory existence ───────────────────────────────────────
check_structure() {
  section "Repository Structure"

  local required_files=(
    ".claude/CLAUDE.md"
    ".claude/architecture.md"
    ".claude/commands/add-app.md"
    ".claude/commands/add-profile.md"
    ".claude/commands/update-dotfile.md"
    ".claude/commands/update-macos-defaults.md"
    ".github/workflows/validate.yml"
    ".editorconfig"
    ".shellcheckrc"
    "README.md"
    "scripts/install.sh"
    "scripts/validate.sh"
    "scripts/lib/brew.sh"
    "scripts/lib/direct.sh"
    "scripts/lib/dotfiles.sh"
    "scripts/lib/macos.sh"
    "scripts/lib/utils.sh"
    "profiles/shared/apps/brew-formulae.txt"
    "profiles/shared/apps/brew-casks.txt"
    "profiles/shared/apps/direct-downloads.yaml"
    "profiles/shared/dotfiles/.zshrc"
    "profiles/shared/dotfiles/.zshenv"
    "profiles/shared/dotfiles/.zprofile"
    "profiles/shared/dotfiles/.gitconfig"
    "profiles/shared/macos/defaults.sh"
    "profiles/work/apps/brew-formulae.txt"
    "profiles/work/apps/brew-casks.txt"
    "profiles/work/apps/direct-downloads.yaml"
    "profiles/work/dotfiles/.zshrc.local"
    "profiles/work/macos/defaults.sh"
    "profiles/personal/apps/brew-formulae.txt"
    "profiles/personal/apps/brew-casks.txt"
    "profiles/personal/apps/direct-downloads.yaml"
    "profiles/personal/dotfiles/.zshrc.local"
    "profiles/personal/macos/defaults.sh"
  )

  local f
  for f in "${required_files[@]}"; do
    if [[ -f "${REPO_ROOT}/${f}" ]]; then
      pass "${f}"
    else
      fail "Missing required file: ${f}"
    fi
  done
}

# ─── App list file format ─────────────────────────────────────────────────────
check_app_lists() {
  section "App List Format"

  local txt_files
  txt_files="$(find "${REPO_ROOT}/profiles" -name "*.txt" 2>/dev/null)"

  if [[ -z "$txt_files" ]]; then
    warn "No .txt app list files found"
    return 0
  fi

  local file
  while IFS= read -r file; do
    local line_num=0
    local file_ok=true
    while IFS= read -r line; do
      (( line_num++ )) || true
      # Skip blanks and comments
      [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
      # Strip inline comments
      local entry="${line%%#*}"
      entry="${entry%%[[:space:]]}"
      # Homebrew names must not contain spaces (hyphens ok, no spaces)
      if [[ "$entry" =~ [[:space:]] ]]; then
        fail "${file}:${line_num}: entry contains spaces (did you mean a hyphen?): '${line}'"
        file_ok=false
      fi
    done < "$file"
    if $file_ok; then
      pass "$(realpath --relative-to="$REPO_ROOT" "$file" 2>/dev/null || basename "$file")"
    fi
  done <<< "$txt_files"
}

# ─── direct-downloads.yaml validation ────────────────────────────────────────
check_direct_yamls() {
  section "Direct Downloads YAML"

  local yaml_files
  yaml_files="$(find "${REPO_ROOT}/profiles" -name "direct-downloads.yaml" 2>/dev/null)"

  local file
  while IFS= read -r file; do
    local rel_path
    rel_path="$(realpath --relative-to="$REPO_ROOT" "$file" 2>/dev/null || basename "$file")"

    # File must exist and be readable (already guaranteed by find)
    # Check that every app block has required fields: name, url, type, app_name
    local in_block=false
    local block_name="" has_url=false has_type=false has_app_name=false
    local block_errors=0
    local line_num=0

    while IFS= read -r line; do
      (( line_num++ )) || true
      [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

      if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name: ]]; then
        # Flush previous block
        if $in_block; then
          if ! $has_url;      then fail "${rel_path}: '${block_name}' missing 'url'"; (( block_errors++ )) || true; fi
          if ! $has_type;     then fail "${rel_path}: '${block_name}' missing 'type'"; (( block_errors++ )) || true; fi
          if ! $has_app_name; then fail "${rel_path}: '${block_name}' missing 'app_name'"; (( block_errors++ )) || true; fi
        fi
        block_name="${line#*name:}"
        block_name="${block_name//\"/}"
        block_name="${block_name//[[:space:]]/}"
        in_block=true
        has_url=false
        has_type=false
        has_app_name=false
      elif [[ "$line" =~ ^[[:space:]]*url: ]];      then has_url=true
      elif [[ "$line" =~ ^[[:space:]]*type: ]];     then has_type=true
      elif [[ "$line" =~ ^[[:space:]]*app_name: ]]; then has_app_name=true
      fi
    done < "$file"

    # Flush last block
    if $in_block; then
      if ! $has_url;      then fail "${rel_path}: '${block_name}' missing 'url'"; (( block_errors++ )) || true; fi
      if ! $has_type;     then fail "${rel_path}: '${block_name}' missing 'type'"; (( block_errors++ )) || true; fi
      if ! $has_app_name; then fail "${rel_path}: '${block_name}' missing 'app_name'"; (( block_errors++ )) || true; fi
    fi

    if [[ "$block_errors" -eq 0 ]]; then
      pass "${rel_path}"
    fi
  done <<< "$yaml_files"
}

# ─── Dotfile filename sanity ──────────────────────────────────────────────────
check_dotfile_names() {
  section "Dotfile Filenames"

  local dotfile_dirs
  dotfile_dirs="$(find "${REPO_ROOT}/profiles" -type d -name "dotfiles" 2>/dev/null)"

  local dir
  while IFS= read -r dir; do
    local file
    while IFS= read -r -d '' file; do
      local name
      name="$(basename "$file")"
      # Must start with a dot (hidden file) or be a known config filename
      if [[ "$name" != .* ]] && [[ "$name" != *.local ]]; then
        warn "Dotfile '${name}' in $(basename "$(dirname "$dir")") doesn't start with '.'"
      else
        pass "$(realpath --relative-to="$REPO_ROOT" "$file" 2>/dev/null || echo "$name")"
      fi
    done < <(find "$dir" -maxdepth 1 -type f -print0)
  done <<< "$dotfile_dirs"
}

# ─── Secrets scan ────────────────────────────────────────────────────────────
check_secrets() {
  section "Secrets Scan"

  local patterns=(
    'AKIA[0-9A-Z]{16}'               # AWS access key
    'aws_secret_access_key\s*='      # AWS secret
    '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'  # Private keys
    'ghp_[A-Za-z0-9]{36}'            # GitHub personal access token
    'github_pat_[A-Za-z0-9_]{82}'    # GitHub fine-grained PAT
    'xox[baprs]-[0-9A-Za-z-]+'       # Slack token
    'sk-[A-Za-z0-9]{32,}'            # OpenAI / generic API key
  )

  local found=false
  local pattern
  for pattern in "${patterns[@]}"; do
    local matches
    # shellcheck disable=SC2063
    matches="$(grep -rEn "$pattern" "${REPO_ROOT}" \
      --include="*.sh" --include="*.txt" --include="*.yaml" \
      --include="*.yml" --include="*.env" --include="*.md" \
      --exclude-dir=".git" 2>/dev/null || true)"
    if [[ -n "$matches" ]]; then
      fail "Possible secret pattern '${pattern}' found:"
      printf "%s\n" "$matches" >&2
      found=true
    fi
  done

  if ! $found; then
    pass "No secret patterns detected"
  fi
}

# ─── Script syntax check ─────────────────────────────────────────────────────
check_syntax() {
  section "Shell Script Syntax"

  local sh_files
  sh_files="$(find "${REPO_ROOT}/scripts" "${REPO_ROOT}/profiles" -name "*.sh" 2>/dev/null)"

  local file
  while IFS= read -r file; do
    local rel_path
    rel_path="$(realpath --relative-to="$REPO_ROOT" "$file" 2>/dev/null || basename "$file")"
    if bash -n "$file" 2>/dev/null; then
      pass "${rel_path}"
    else
      fail "${rel_path}: syntax error"
      bash -n "$file" || true
    fi
  done <<< "$sh_files"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  printf "\n${BOLD}mac-daddy — repo validation${RESET}\n"
  printf "Repo: %s\n" "$REPO_ROOT"

  check_structure
  check_app_lists
  check_direct_yamls
  check_dotfile_names
  check_secrets
  check_syntax

  printf "\n"
  if [[ "$ERRORS" -gt 0 ]]; then
    printf "${RED}${BOLD}Validation failed: %d error(s), %d warning(s)${RESET}\n\n" \
      "$ERRORS" "$WARNINGS"
    exit 1
  elif [[ "$WARNINGS" -gt 0 ]]; then
    printf "${YELLOW}${BOLD}Validation passed with %d warning(s)${RESET}\n\n" "$WARNINGS"
  else
    printf "${GREEN}${BOLD}All checks passed.${RESET}\n\n"
  fi
}

main "$@"
