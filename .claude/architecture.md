# mac-daddy — Architecture Reference

## Data Flow: install.sh Execution Order

```
install.sh
│
├─ [parse args] → PROFILE, DRY_RUN, VERBOSE, SKIP_MACOS_DEFAULTS
├─ [setup log]  → ~/.mac-daddy/logs/install-YYYYMMDD-HHMMSS.log
├─ [source lib] → utils.sh, brew.sh, direct.sh, dotfiles.sh, macos.sh
│
├─ 1.  run_preflight()
│       ├─ uname -s == Darwin? (skip with warning in dry-run on Linux)
│       ├─ sw_vers -productVersion >= 13.0?
│       ├─ curl HEAD https://formulae.brew.sh (internet check)
│       └─ xcode-select -p (Xcode CLT check)
│
├─ 2.  install_homebrew()
│       ├─ command_exists brew? → run_or_dry brew update
│       └─ else → /bin/bash official installer + eval shellenv
│
├─ 3a. install_oh_my_zsh()
│       └─ -d ~/.oh-my-zsh? → skip; else RUNZSH=no CHSH=no sh install.sh
│
├─ 3b. install_zsh_plugins()
│       ├─ clone zsh-autosuggestions → ${ZSH_CUSTOM}/plugins/ (if missing)
│       └─ clone zsh-syntax-highlighting → ${ZSH_CUSTOM}/plugins/ (if missing)
│
├─ 4.  install_formulae(shared/apps/brew-formulae.txt)
├─ 5.  install_casks(shared/apps/brew-casks.txt)
├─ 6.  install_formulae(${PROFILE}/apps/brew-formulae.txt)
├─ 7.  install_casks(${PROFILE}/apps/brew-casks.txt)
│
├─ 8.  install_direct_downloads(shared/apps/direct-downloads.yaml)
├─ 9.  install_direct_downloads(${PROFILE}/apps/direct-downloads.yaml)
│
├─ 10. apply_dotfiles(shared/dotfiles/)
├─ 11. apply_dotfiles(${PROFILE}/dotfiles/)
│
├─ 12. apply_macos_defaults(shared/macos/defaults.sh)
├─ 13. apply_macos_defaults(${PROFILE}/macos/defaults.sh)
│
├─ 14. brew cleanup
└─ 15. print_summary()
```

## Smart Diff Algorithm

### Homebrew (brew.sh)

Single `brew list --formula` (or `--cask`) call at the start of each function builds
an in-memory string. Each package name is checked with `grep -qx` (exact-line match)
against that string. Cost: O(1) `brew list` call + O(n) grep per package.

```
installed_formulae="$(brew list --formula)"   # one call
for formula in file:
  if echo "$installed_formulae" | grep -qx "$formula"; then skip
  else brew install "$formula"
```

Casks additionally heuristically check `/Applications` with a case-insensitive
`find | grep` for the cask name (hyphens → spaces) to skip apps installed
outside Homebrew.

### Direct Downloads (direct.sh)

`app_exists()` checks `/Applications/${app_name}` and `~/Applications/${app_name}`.
If either exists, skip download entirely. No network request is made for
already-installed apps.

### Dotfiles (dotfiles.sh)

`readlink "$target"` compares the current symlink destination against the repo path.
Three cases:
1. Matches → skip
2. Exists but points elsewhere → remove and re-link
3. Exists as a regular file → backup to `~/.mac-daddy/backups/dotfiles/` with
   timestamp suffix, then symlink
4. Missing → symlink directly

## Symlink Conflict Resolution

```
~/.zshrc (target)
    │
    ├─ is symlink AND readlink == repo_path? → SKIP
    ├─ is symlink AND readlink != repo_path? → rm + ln -sf
    ├─ is regular file?                      → mv to backup/ + ln -sf
    └─ does not exist?                       → ln -sf
```

Backups live at: `~/.mac-daddy/backups/dotfiles/<filename>.<YYYYMMDD-HHMMSS>.bak`

## Profile Layering (.zshrc → .zshrc.local)

```
zsh startup
    │
    ├─ ~/.zshenv        → symlink to profiles/shared/dotfiles/.zshenv
    ├─ ~/.zprofile      → symlink to profiles/shared/dotfiles/.zprofile
    └─ ~/.zshrc         → symlink to profiles/shared/dotfiles/.zshrc
            │
            └─ [[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
                    │
                    └─ ~/.zshrc.local → symlink to profiles/{work|personal}/dotfiles/.zshrc.local
```

The shared `.zshrc` sources `~/.zshrc.local` at the end if it exists. The symlink
for `.zshrc.local` is created by the profile-specific dotfiles step. This means:
- Shared config is always loaded
- Profile config is layered on top and can override anything

## direct-downloads.yaml Parser

No external YAML library. The `_parse_direct_yaml()` function uses a single `awk`
invocation. It processes the YAML line-by-line with these rules:

- Each app block starts with a line matching `^[[:space:]]*-[[:space:]]*name:`
- On a new `name:` line, the previous block is flushed to stdout as TSV
- Field extraction uses two `sub()` calls:
  1. Strip key prefix: `sub(/^[[:space:]]*[^:]*:[[:space:]]*"?/, "", r)`
  2. Strip trailing quote/spaces/comment: `sub(/"?[[:space:]]*(#.*)?$/, "", r)`
- Output: `name\turl\ttype\tapp_name\tchecksum\tpost_install` (one line per app)
- Empty yaml (`apps: []` or no app blocks) produces zero lines — safe

The caller reads TSV with `while IFS=$'\t' read -r name url type ...`

## macOS Defaults Organization

`profiles/shared/macos/defaults.sh` is divided into domain sections:

| Domain | Settings |
|--------|----------|
| NSGlobalDomain | Save panel, print panel, iCloud, quarantine, key repeat, locale |
| com.apple.dock | Size, magnification, autohide, position, animation speeds |
| com.apple.finder | Extensions, bars, path display, search scope, .DS_Store |
| com.apple.Safari | Dev menu, spell check, autofill |
| com.apple.screensaver | Password requirement, delay |
| NSGlobalDomain (display) | Font smoothing, HiDPI |
| com.apple.TextEdit | Plain text mode, encoding |
| com.apple.ActivityMonitor | Process view, Dock icon |
| com.apple.ImageCapture | Photo auto-open prevention |
| com.apple.terminal | UTF-8 encoding |
| com.apple.TimeMachine | New disk prompt |

Profile-specific `defaults.sh` files run after shared and can override any key
by writing to the same domain + key.

`apply_macos_defaults()` in `macos.sh` restarts Dock, Finder, SystemUIServer, and
cfprefsd after sourcing each defaults file.

## Logging and Error Handling Strategy

- `LOG_FILE` is set in `install.sh` and exported; all `_log()` calls in utils.sh
  write to both stdout and the log file
- `set -euo pipefail` is active in `install.sh` and `validate.sh` only
- Library files are sourced — adding `set -e` to sourced files would affect the
  parent shell, so they rely on the parent's error handling
- Non-critical failures (single formula install failure) use `(( count++ )) || true`
  to survive `set -e` and continue; the failure is logged and counted
- Critical failures (no internet, wrong OS, missing Xcode CLT) call `exit 1`
  directly from `run_preflight()`
- `run_or_dry` prevents any real system change when `DRY_RUN=true`

## Flag System Design

Flags are parsed in `install.sh` before sourcing lib files. They are exported as
environment variables so all sourced lib functions can read them without needing
them passed as arguments:

| Flag | Variable | Default | Scope |
|------|----------|---------|-------|
| `--dry-run` | `DRY_RUN` | `false` | All lib functions via `run_or_dry` / `is_dry_run` |
| `--verbose` | `VERBOSE` | `false` | `run_or_dry` prints the command before running |
| `--skip-macos-defaults` | `SKIP_MACOS_DEFAULTS` | `false` | `apply_macos_defaults` in macos.sh |

Flags can appear in any position in the argument list alongside the profile name.
