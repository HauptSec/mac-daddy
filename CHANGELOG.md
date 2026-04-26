# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- Initial project structure: `work` and `personal` profiles with shared base layer
- `scripts/install.sh` — main entry point with `--dry-run`, `--verbose`, `--skip-macos-defaults` flags
- `scripts/validate.sh` — repo structure and format validation
- `scripts/lib/brew.sh` — smart-diff Homebrew formula and cask installation
- `scripts/lib/direct.sh` — DMG/PKG direct download installation with YAML parser
- `scripts/lib/dotfiles.sh` — symlink management with timestamped backup on conflict
- `scripts/lib/macos.sh` — macOS system preferences via `defaults write`
- `scripts/lib/utils.sh` — shared logging, guards, and `run_or_dry` utilities
- Shared dotfiles: `.zshrc`, `.zshenv`, `.zprofile`, `.gitconfig`
- Comprehensive `profiles/shared/macos/defaults.sh` covering 10 system domains
- Profile-specific dotfiles (`.zshrc.local`) and macOS override files
- `.github/workflows/validate.yml` — CI with shellcheck, structure validation, and dry-run smoke tests
- `.claude/` documentation: `CLAUDE.md`, `architecture.md`, and command guides
