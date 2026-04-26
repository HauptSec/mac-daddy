#!/usr/bin/env bash
# Direct download (DMG/PKG) installation functions.
# Sourced by install.sh — do NOT add set -euo pipefail here.

# Shared temp directory; cleaned up via trap in install.sh
DIRECT_TMPDIR=""

# Creates the shared temp dir on first call
_ensure_tmpdir() {
  if [[ -z "$DIRECT_TMPDIR" ]]; then
    DIRECT_TMPDIR="$(mktemp -d)"
    # Trap registered in install.sh; register a local one as safety net
    # shellcheck disable=SC2064
    trap "rm -rf '${DIRECT_TMPDIR}'" EXIT
  fi
}

# Parses direct-downloads.yaml using awk and outputs TSV (no external YAML deps)
# Output: name<TAB>url<TAB>type<TAB>app_name<TAB>checksum<TAB>post_install
_parse_direct_yaml() {
  local yaml_file="$1"
  awk '
    function strip(s,    r) {
      r = s
      # Remove leading whitespace + key + colon + optional opening quote
      sub(/^[[:space:]]*[^:]*:[[:space:]]*"?/, "", r)
      # Remove trailing quote, spaces, and inline comments
      sub(/"?[[:space:]]*(#.*)?$/, "", r)
      return r
    }
    function flush() {
      if (n != "") print n "\t" u "\t" t "\t" a "\t" c "\t" p
      n=""; u=""; t=""; a=""; c=""; p=""
    }
    BEGIN { n=""; u=""; t=""; a=""; c=""; p="" }
    /^[[:space:]]*-[[:space:]]*name:/  { flush(); n=strip($0) }
    /^[[:space:]]*url:/                { u=strip($0) }
    /^[[:space:]]*type:/               { t=strip($0) }
    /^[[:space:]]*app_name:/           { a=strip($0) }
    /^[[:space:]]*checksum:/           { c=strip($0) }
    /^[[:space:]]*post_install:/       { p=strip($0) }
    END { flush() }
  ' "$yaml_file"
}

# Reads a direct-downloads.yaml file and installs each listed app
install_direct_downloads() {
  local yaml_file="$1"

  if [[ ! -f "$yaml_file" ]]; then
    log_warn "Direct downloads file not found: $yaml_file"
    return 0
  fi

  _ensure_tmpdir

  local installed_count=0 skipped_count=0 failed_count=0

  while IFS=$'\t' read -r name url type app_name checksum post_install; do
    [[ -z "$name" ]] && continue
    if _install_direct_app "$name" "$url" "$type" "$app_name" "$checksum" "$post_install"; then
      # _install_direct_app logs skip internally; count based on exit behavior
      (( installed_count++ )) || true
    else
      (( failed_count++ )) || true
    fi
  done < <(_parse_direct_yaml "$yaml_file")

  log_info "Direct downloads — installed: ${installed_count}, failed: ${failed_count}"
}

# Installs a single app from a direct download URL
_install_direct_app() {
  local name="$1"
  local url="$2"
  local type="$3"
  local app_name="$4"
  local checksum="$5"
  local post_install="$6"

  if [[ -z "$url" || -z "$type" ]]; then
    log_error "  ${name}: missing url or type — skipping"
    return 1
  fi

  local check_name="${app_name:-${name}.app}"
  if app_exists "$check_name"; then
    log_warn "  skip (already installed): ${name}"
    return 0
  fi

  log_info "  downloading: ${name}"
  local dest="${DIRECT_TMPDIR}/${name}.${type}"

  if ! run_or_dry curl -fsSL --progress-bar -o "$dest" "$url"; then
    log_error "  download failed: ${name}"
    return 1
  fi

  if [[ -n "$checksum" ]]; then
    _verify_checksum "$dest" "$checksum" "$name" || return 1
  fi

  case "$type" in
    dmg) _install_from_dmg "$dest" "$name" ;;
    pkg) _install_from_pkg "$dest" "$name" ;;
    *)
      log_error "  ${name}: unknown type '${type}'"
      return 1
      ;;
  esac

  if [[ -n "$post_install" ]]; then
    log_info "  post-install hook: ${post_install}"
    run_or_dry bash -c "$post_install"
  fi
}

# Verifies a downloaded file against a "algo:hexdigest" checksum string
_verify_checksum() {
  local file="$1"
  local checksum="$2"
  local name="$3"
  local algo="${checksum%%:*}"
  local expected="${checksum##*:}"
  local actual

  case "$algo" in
    sha256) actual="$(shasum -a 256 "$file" | awk '{print $1}')" ;;
    sha512) actual="$(shasum -a 512 "$file" | awk '{print $1}')" ;;
    *)
      log_warn "  ${name}: unknown checksum algorithm '${algo}' — skipping verification"
      return 0
      ;;
  esac

  if [[ "$actual" != "$expected" ]]; then
    log_error "  ${name}: checksum mismatch"
    log_error "    expected: ${expected}"
    log_error "    actual:   ${actual}"
    return 1
  fi
  log_success "  ${name}: checksum OK"
}

# Mounts a DMG, copies the .app bundle to /Applications, then unmounts
_install_from_dmg() {
  local dmg="$1"
  local name="$2"
  local mount_point="${DIRECT_TMPDIR}/mount_${name}"

  mkdir -p "$mount_point"
  log_info "  mounting DMG: ${name}"

  if ! run_or_dry hdiutil attach -quiet -nobrowse -mountpoint "$mount_point" "$dmg"; then
    log_error "  failed to mount DMG: ${name}"
    return 1
  fi

  local app_path
  app_path="$(find "$mount_point" -maxdepth 2 -name "*.app" 2>/dev/null | head -1)"

  if [[ -z "$app_path" ]]; then
    log_error "  no .app bundle found in DMG: ${name}"
    run_or_dry hdiutil detach -quiet "$mount_point" 2>/dev/null || true
    return 1
  fi

  log_info "  copying $(basename "$app_path") to /Applications"
  run_or_dry cp -R "$app_path" /Applications/

  run_or_dry hdiutil detach -quiet "$mount_point" || true
  log_success "  installed: ${name}"
}

# Runs a PKG installer (requires sudo)
_install_from_pkg() {
  local pkg="$1"
  local name="$2"
  log_info "  running PKG installer for ${name} (requires sudo)"
  # sudo required by macOS installer for system-wide PKG installation
  run_or_dry sudo installer -pkg "$pkg" -target /
  log_success "  installed: ${name}"
}
