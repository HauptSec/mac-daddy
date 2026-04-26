#!/usr/bin/env bash
# Personal-profile macOS overrides — applied after shared defaults.
# Use this to override any setting from profiles/shared/macos/defaults.sh
# for the personal context.
# NOTE: This file is sourced by macos.sh — do NOT add set -euo pipefail here.

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
