# .zprofile — sourced once at login shell startup.
# Use for PATH modifications and one-time environment setup.
# Avoid slow commands here (keeps login shells snappy).

# ─── Homebrew (arch-aware) ────────────────────────────────────────────────────
# Apple Silicon Macs use /opt/homebrew; Intel Macs use /usr/local.
if [[ "$(uname -m)" == "arm64" ]]; then
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
else
  if [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
