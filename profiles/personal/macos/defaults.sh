#!/usr/bin/env bash
# Personal-profile macOS overrides — applied after shared defaults.
# Use this to override any setting from profiles/shared/macos/defaults.sh
# for the personal context.
# NOTE: This file is sourced by macos.sh — do NOT add set -euo pipefail here.

###############################################################################
# Dock apps — personal (full order, overrides shared)
###############################################################################

if command -v dockutil &>/dev/null; then
  _dock_add() { [[ -d "$1" ]] && dockutil --add "$1" --no-restart 2>/dev/null || true; }

  dockutil --remove all --no-restart 2>/dev/null || true

  _dock_add "/Applications/iTerm.app"
  _dock_add "/Applications/Vivaldi.app"
  _dock_add "/Applications/Claude.app"
  _dock_add "/Applications/Visual Studio Code.app"
  _dock_add "/Applications/Termius.app"
  _dock_add "/Applications/Obsidian.app"

  unset -f _dock_add
fi

###############################################################################
# Personal Dock overrides
###############################################################################

# TODO: Uncomment and customize as needed

# Larger Dock for personal/casual use
# defaults write com.apple.dock tilesize -int 56

# Keep Dock at the bottom (default, but explicit here for clarity)
# defaults write com.apple.dock orientation -string "bottom"

###############################################################################
# Personal Finder overrides
###############################################################################

# TODO: Uncomment and customize as needed

# Open Finder to a personal projects folder
# defaults write com.apple.finder NewWindowTarget -string "PfLo"
# defaults write com.apple.finder NewWindowTargetPath -string "file:///Users/${USER}/Projects/"

###############################################################################
# Personal screensaver / lock overrides
###############################################################################

# TODO: Slightly more relaxed password delay for home machine
# defaults write com.apple.screensaver askForPasswordDelay -int 5
