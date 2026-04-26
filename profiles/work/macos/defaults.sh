#!/usr/bin/env bash
# Work-profile macOS overrides — applied after shared defaults.
# Use this to override any setting from profiles/shared/macos/defaults.sh
# for the work context.
# NOTE: This file is sourced by macos.sh — do NOT add set -euo pipefail here.

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
