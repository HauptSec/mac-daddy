# ─── Powerlevel10k instant prompt ────────────────────────────────────────────
# Must stay near the top. Anything requiring console input goes above this block.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ─── Oh My Zsh ────────────────────────────────────────────────────────────────
export ZSH="${HOME}/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins — zsh-autosuggestions, zsh-syntax-highlighting, and powerlevel10k are
# cloned to ${ZSH_CUSTOM}/ by install.sh; the rest ship with Oh My Zsh.
plugins=(
  git
  autojump
  sudo
  vscode
  zsh-autosuggestions
  zsh-syntax-highlighting
  z
  fzf
)

source "${ZSH}/oh-my-zsh.sh"

# ─── PATH ─────────────────────────────────────────────────────────────────────
# Homebrew — arch-aware (Apple Silicon: /opt/homebrew, Intel: /usr/local)
if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# User-local binaries
export PATH="${HOME}/.local/bin:${PATH}"

# ─── History ──────────────────────────────────────────────────────────────────
export HISTFILE="${HOME}/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

setopt SHARE_HISTORY       # Share history across sessions
setopt HIST_IGNORE_DUPS    # Don't record duplicate consecutive commands
setopt HIST_IGNORE_SPACE   # Don't record commands starting with a space
setopt HIST_VERIFY         # Show expanded history before executing

# ─── Aliases ──────────────────────────────────────────────────────────────────
alias ll='ls -lhF'
alias la='ls -lahF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -pv'
alias df='df -h'
alias du='du -h'
alias which='type -a'

# Use modern replacements when available
if command -v eza &>/dev/null; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lh --group-directories-first'
  alias la='eza -lah --group-directories-first'
fi

if command -v bat &>/dev/null; then
  alias cat='bat --paging=never'
fi

# ─── zoxide (better cd) ───────────────────────────────────────────────────────
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# ─── fzf ──────────────────────────────────────────────────────────────────────
if [[ -f "${HOME}/.fzf.zsh" ]]; then
  source "${HOME}/.fzf.zsh"
fi

# ─── User Customizations ──────────────────────────────────────────────────────
# Add personal overrides below this line.
# Do not put secrets here — use ~/.zshrc.local (managed per-profile by mac-daddy).

# Load profile-specific config (work or personal) — sourced last so it can
# override anything above. The symlink is managed by mac-daddy's dotfiles step.
[[ -f "${HOME}/.zshrc.local" ]] && source "${HOME}/.zshrc.local"

# ─── Powerlevel10k config ─────────────────────────────────────────────────────
[[ ! -f "${HOME}/.p10k.zsh" ]] || source "${HOME}/.p10k.zsh"
