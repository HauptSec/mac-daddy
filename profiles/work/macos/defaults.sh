#!/usr/bin/env bash
# Work-profile macOS overrides — applied after shared defaults.
# Use this to override any setting from profiles/shared/macos/defaults.sh
# for the work context.
# NOTE: This file is sourced by macos.sh — do NOT add set -euo pipefail here.

###############################################################################
# Dock apps — work (full order, overrides shared)
###############################################################################

if command -v dockutil &>/dev/null; then
  _dock_add() { [[ -d "$1" ]] && dockutil --add "$1" --no-restart 2>/dev/null || true; }

  dockutil --remove all --no-restart 2>/dev/null || true

  _dock_add "/Applications/iTerm.app"
  _dock_add "/Applications/Vivaldi.app"
  _dock_add "/Applications/Slack.app"
  _dock_add "/Applications/Microsoft Teams.app"
  _dock_add "/Applications/Microsoft Outlook.app"
  _dock_add "/Applications/Microsoft OneNote.app"
  _dock_add "/Applications/ChatGPT.app"
  _dock_add "/Applications/Claude.app"
  _dock_add "/Applications/Visual Studio Code.app"
  _dock_add "/System/Applications/Notes.app"
  _dock_add "/Applications/Delinea Connection Manager.app"
  _dock_add "/Applications/Termius.app"
  _dock_add "/Applications/Postman.app"
  _dock_add "/Applications/Citrix Workspace.app"

  unset -f _dock_add
fi

###############################################################################
# Work-specific Dock overrides
###############################################################################

# TODO: Uncomment and customize as needed

# Keep Dock on the left for more vertical screen space on wide monitors
# defaults write com.apple.dock orientation -string "left"

# Smaller Dock icon size for denser work setup
# defaults write com.apple.dock tilesize -int 36

###############################################################################
# Work-specific Finder overrides
###############################################################################

# TODO: Uncomment and customize as needed

# Set a work-specific default folder for new Finder windows
# defaults write com.apple.finder NewWindowTarget -string "PfLo"
# defaults write com.apple.finder NewWindowTargetPath -string "file:///Users/${USER}/Work/"

###############################################################################
# Work-specific screen lock
###############################################################################

# TODO: Stricter lock policy for work machines
# defaults write com.apple.screensaver askForPasswordDelay -int 0
