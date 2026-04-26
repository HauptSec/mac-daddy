# .zshenv — sourced for every zsh session (interactive, non-interactive, scripts).
# Keep this minimal: only essential environment variables that must be available
# in ALL contexts (including cron jobs and SSH sessions without a login shell).

# ─── XDG Base Directory spec ──────────────────────────────────────────────────
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_STATE_HOME="${HOME}/.local/state"

# ─── Editor ───────────────────────────────────────────────────────────────────
# TODO: Set your preferred editor (vim, nvim, code, nano, etc.)
export EDITOR="vim"
export VISUAL="${EDITOR}"

# ─── Language / Locale ────────────────────────────────────────────────────────
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# ─── mac-daddy home ───────────────────────────────────────────────────────────
export MAC_DADDY_HOME="${HOME}/.mac-daddy"
