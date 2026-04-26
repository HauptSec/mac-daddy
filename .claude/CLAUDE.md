# mac-daddy — Claude Code Guide

## Purpose

mac-daddy is a shell-based macOS provisioning system. Running `./scripts/install.sh [work|personal]` sets up a new Mac to a fully configured personal state: Homebrew packages, direct-downloaded apps, dotfile symlinks, and macOS system preferences. The system is idempotent — re-running it skips already-installed items.

## Architecture Summary

Install order: preflight → Homebrew → Oh My Zsh + plugins → shared formulae → shared casks → profile formulae → profile casks → shared direct downloads → profile direct downloads → shared dotfiles → profile dotfiles → shared macOS defaults → profile macOS defaults → cleanup → summary report. Libraries in `scripts/lib/` are sourced (not executed) so they share state via exported variables (`DRY_RUN`, `VERBOSE`, `SKIP_MACOS_DEFAULTS`, `LOG_FILE`). See [architecture.md](architecture.md) for the full data flow diagram.

## Directory Structure

```
.claude/
  CLAUDE.md              — this file
  architecture.md        — deep technical reference
  commands/
    add-app.md           — how to add a new app to any profile
    add-profile.md       — how to create a third profile (e.g. client)
    update-dotfile.md    — how to add/modify a dotfile
    update-macos-defaults.md — how to change macOS preferences

.github/workflows/
  validate.yml           — CI: shellcheck + structure validation + dry-run smoke test

profiles/
  shared/                — applies to ALL profiles
    apps/
      brew-formulae.txt  — shared Homebrew CLI tools (one per line)
      brew-casks.txt     — shared Homebrew GUI apps (one per line)
      direct-downloads.yaml — shared apps installed via DMG/PKG
    dotfiles/            — symlinked to $HOME for all profiles
      .zshrc             — main zsh config; sources .zshrc.local at the end
      .zshenv            — env vars loaded in all zsh contexts
      .zprofile          — login-shell setup (Homebrew eval)
      .gitconfig         — git defaults with TODO name/email placeholders
    macos/
      defaults.sh        — comprehensive macOS system preferences
  work/                  — applied AFTER shared, only for the work profile
    apps/                — work-only brew formulae, casks, direct downloads
    dotfiles/
      .zshrc.local       — work-specific PATH/aliases/env vars
    macos/
      defaults.sh        — work-specific macOS preference overrides
  personal/              — applied AFTER shared, only for the personal profile
    apps/                — personal-only brew formulae, casks, direct downloads
    dotfiles/
      .zshrc.local       — personal-specific PATH/aliases/env vars
    macos/
      defaults.sh        — personal-specific macOS preference overrides

scripts/
  install.sh             — main entry point (see usage below)
  validate.sh            — standalone repo validation (also run by CI)
  lib/
    utils.sh             — logging, command_exists, run_or_dry, etc.
    brew.sh              — install_homebrew, install_formulae, install_casks
    direct.sh            — install_direct_downloads (DMG/PKG with YAML parser)
    dotfiles.sh          — apply_dotfiles (symlinks with backup)
    macos.sh             — apply_macos_defaults (sources defaults.sh files)

.editorconfig            — editor settings (UTF-8, LF, indent rules)
.shellcheckrc            — shellcheck configuration
CHANGELOG.md             — keep-a-changelog format release notes
README.md                — user-facing documentation
```

## Three Core Design Principles

1. **Shared/profile layering** — Every step runs shared first, then profile-specific. Profile files add to or override shared settings without modifying them. The `.zshrc → .zshrc.local` pattern applies this to shell config.

2. **Smart diff** — Before installing anything, build an in-memory set of already-installed items (single `brew list` call) and only install what's missing. Never call `brew list` per-item. Direct downloads check `/Applications` for existence. Dotfiles check symlink targets before linking.

3. **Live symlinks** — Dotfiles are symlinked from the repo, not copied. Editing a dotfile in the repo takes effect immediately in the next shell session without re-running install.

## How Profiles Work

- `work` and `personal` are the two supported profiles.
- Each profile directory mirrors the `shared/` structure.
- install.sh processes `shared/` fully, then `profiles/${PROFILE}/`.
- `.zshrc.local` is how profile-specific zsh config is injected — the shared `.zshrc` sources it at the end if it exists.
- macOS defaults work the same way: shared defaults run first, profile defaults run after and can override with new `defaults write` commands for the same key.

## Quick Reference: What to Edit

| I want to…                        | Edit this file                                      |
|-----------------------------------|-----------------------------------------------------|
| Add a brew CLI tool (all profiles) | `profiles/shared/apps/brew-formulae.txt`           |
| Add a brew GUI app (all profiles)  | `profiles/shared/apps/brew-casks.txt`              |
| Add a brew app (work only)         | `profiles/work/apps/brew-casks.txt`                |
| Add a DMG/PKG app                  | relevant `direct-downloads.yaml`                   |
| Change zsh config (all profiles)   | `profiles/shared/dotfiles/.zshrc`                  |
| Add a work-only alias/env var      | `profiles/work/dotfiles/.zshrc.local`              |
| Change macOS system preferences    | `profiles/shared/macos/defaults.sh`                |
| Override a pref for work only      | `profiles/work/macos/defaults.sh`                  |

## Usage

```bash
# Interactive profile selection
./scripts/install.sh

# Specify profile
./scripts/install.sh work
./scripts/install.sh personal

# Dry run — print all actions without executing anything
./scripts/install.sh work --dry-run

# Verbose + dry run
./scripts/install.sh work --dry-run --verbose

# Skip macOS defaults (useful when testing on a shared machine)
./scripts/install.sh work --skip-macos-defaults

# All flags combinable
./scripts/install.sh personal --dry-run --verbose --skip-macos-defaults
```

## Testing and Validation

```bash
# Validate repo structure and format (runs same checks as CI)
bash scripts/validate.sh

# Test install logic without making any changes
./scripts/install.sh work --dry-run
./scripts/install.sh personal --dry-run

# Check all shell scripts for errors
shellcheck scripts/**/*.sh profiles/**/*.sh
```

## The --dry-run Workflow

Before applying to a real machine:
1. `bash scripts/validate.sh` — catch structural/format errors
2. `./scripts/install.sh work --dry-run` — verify the full install plan
3. Review the output for unexpected items
4. Run without `--dry-run` when satisfied

## Common Pitfalls

- **No secrets** — `.zshrc.local`, `.gitconfig`, and all dotfiles are tracked in git. Put secrets in a password manager or `~/.secrets` (not tracked). The validate.sh script scans for common patterns.
- **No absolute paths in dotfiles** — use `${HOME}` not `~` or `/Users/yourusername/`. Dotfiles symlink into any user's home.
- **Homebrew cask names vs app names** — the cask name (e.g. `google-chrome`) differs from the app name (`Google Chrome.app`). Use `brew search` to find the correct cask name.
- **Direct downloads need real URLs** — the `url` field in `direct-downloads.yaml` must be a direct file download link, not a landing page.
- **macOS defaults may require logout** — some preferences (font smoothing, HiDPI) only apply after logging out. These are noted inline in `defaults.sh`.
- **Dotfiles are flat** — `apply_dotfiles` only symlinks files at the top level of a dotfiles directory, not subdirectories. For nested config dirs (e.g. `~/.config/nvim/`), add an explicit step.

## Links

- [Architecture & data flow](architecture.md)
- [Add an app](commands/add-app.md)
- [Add a profile](commands/add-profile.md)
- [Update a dotfile](commands/update-dotfile.md)
- [Update macOS defaults](commands/update-macos-defaults.md)
