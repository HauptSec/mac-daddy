#!/usr/bin/env bash
# Shared macOS system preferences — applied for all profiles.
# Each section targets a specific domain. Edit values to match your preferences.
# NOTE: Some settings require logout or restart to take effect (marked below).
# NOTE: This file is sourced by macos.sh — do NOT add set -euo pipefail here.

# ─── Close open System Preferences to prevent conflicts ──────────────────────
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || \
  osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true

###############################################################################
# Global / NSGlobalDomain
###############################################################################

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Disable "Are you sure you want to open this application?" quarantine dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable automatic termination of inactive apps
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

# Disable startup sound (requires sudo)
sudo nvram SystemAudioVolume=" " 2>/dev/null || true

# Set sidebar icon size to medium (1=small, 2=medium, 3=large)
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2

# Set highlight color to blue (default; change to other values for custom color)
defaults write NSGlobalDomain AppleHighlightColor -string "0.698039 0.843137 1.000000 Blue"

# Enable tap to click for the built-in trackpad
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Enable full keyboard access for all controls (Tab through all UI elements)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Set a fast key repeat rate (lower = faster; system minimum is 2)
defaults write NSGlobalDomain KeyRepeat -int 2
# Set short initial key repeat delay (lower = shorter; system minimum is 15)
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable smart quotes (prevents autocorrection of straight quotes)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable autocorrect
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Set language and locale
defaults write NSGlobalDomain AppleLanguages -array "en-US" "en"
defaults write NSGlobalDomain AppleLocale -string "en_US@currency=USD"
defaults write NSGlobalDomain AppleMeasurementUnits -string "Inches"
defaults write NSGlobalDomain AppleMetricUnits -bool false

###############################################################################
# Dock
###############################################################################

# Set Dock icon size (pixels)
defaults write com.apple.dock tilesize -int 48

# Enable magnification when hovering
defaults write com.apple.dock magnification -bool true

# Set magnification size
defaults write com.apple.dock largesize -int 64

# Position (bottom, left, right)
defaults write com.apple.dock orientation -string "bottom"

# Minimize windows using scale effect (scale is faster than genie)
defaults write com.apple.dock mineffect -string "scale"

# Enable spring loading for all Dock items (hover to activate)
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# Show indicator lights for open applications
defaults write com.apple.dock show-process-indicators -bool true

# Enable auto-hide
defaults write com.apple.dock autohide -bool true

# Remove auto-hide delay (show/hide immediately)
defaults write com.apple.dock autohide-delay -float 0

# Speed up the auto-hide animation
defaults write com.apple.dock autohide-time-modifier -float 0.5

# Don't show recent applications in the Dock
defaults write com.apple.dock show-recents -bool false

# Speed up Mission Control animation
defaults write com.apple.dock expose-animation-duration -float 0.1

###############################################################################
# Finder
###############################################################################

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status bar at the bottom of Finder windows
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar at the bottom of Finder windows
defaults write com.apple.finder ShowPathbar -bool true

# Allow text selection in Quick Look previews
defaults write com.apple.finder QLEnableTextSelection -bool true

# Display full POSIX path in Finder window title bar
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Disable warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Enable spring loading for directories (hover over folder to open it)
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

# Remove spring loading delay
defaults write NSGlobalDomain com.apple.springing.delay -float 0

# Set default search scope to current folder (not entire Mac)
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Avoid creating .DS_Store files on network and USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Show ~/Library folder (hidden by default since macOS Lion)
chflags nohidden "${HOME}/Library" 2>/dev/null || true

# Show /Volumes folder (requires sudo)
sudo chflags nohidden /Volumes 2>/dev/null || true

# Expand "Get Info" panes: General, Open with, Sharing & Permissions
defaults write com.apple.finder FXInfoPanesExpanded -dict \
  General    -bool true \
  OpenWith   -bool true \
  Privileges -bool true

# Set new Finder window default location to home folder
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# Use list view by default (Nlsv=list, icnv=icon, clmv=column, glyv=gallery)
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

###############################################################################
# Safari
###############################################################################

# Enable the Develop menu and Web Inspector
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari \
  com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Enable continuous spell checking
defaults write com.apple.Safari WebContinuousSpellCheckingEnabled -bool true

# Disable AutoFill forms
defaults write com.apple.Safari AutoFillFromAddressBook -bool false
defaults write com.apple.Safari AutoFillPasswords -bool false
defaults write com.apple.Safari AutoFillCreditCardData -bool false
defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false

###############################################################################
# Screen & Security
###############################################################################

# Require password immediately after sleep or screensaver
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Enable subpixel font rendering on non-Apple displays
# (0=off, 1=light, 2=medium, 3=heavy; requires logout — see architecture.md)
defaults write NSGlobalDomain AppleFontSmoothing -int 1

# Enable HiDPI display modes (activates retina-resolution options in Displays prefs)
sudo defaults write /Library/Preferences/com.apple.windowserver \
  DisplayResolutionEnabled -bool true 2>/dev/null || true

###############################################################################
# TextEdit
###############################################################################

# Use plain text mode by default (instead of rich text)
defaults write com.apple.TextEdit RichText -int 0

# Set encoding for plain text to UTF-8 (4)
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

###############################################################################
# Activity Monitor
###############################################################################

# Show all processes (not just user processes)
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Visualize CPU usage in the Dock icon (5=CPU history graph)
defaults write com.apple.ActivityMonitor IconType -int 5

# Sort by CPU usage descending
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# Photos
###############################################################################

# Prevent Photos from opening automatically when devices (iPhone, camera) plug in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

###############################################################################
# Terminal / iTerm2
###############################################################################

# Only use UTF-8 encoding in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

###############################################################################
# Time Machine
###############################################################################

# Do not prompt to use new drives as Time Machine backup volumes
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

###############################################################################
# Dock apps — shared (dockutil)
# Edit the list below to change pinned apps and order.
# Profile-specific apps are appended in profiles/{work,personal}/macos/defaults.sh
###############################################################################

if command -v dockutil &>/dev/null; then
  _dock_add() { [[ -d "$1" ]] && dockutil --add "$1" --no-restart 2>/dev/null || true; }

  dockutil --remove all --no-restart 2>/dev/null || true

  _dock_add "/System/Library/CoreServices/Finder.app"
  _dock_add "/Applications/iTerm.app"
  _dock_add "/Applications/Visual Studio Code.app"
  _dock_add "/Applications/Vivaldi.app"
  _dock_add "/Applications/Claude.app"

  unset -f _dock_add
fi

###############################################################################
# Process restarts — triggered by macos.sh after this file is sourced
###############################################################################
# (Dock, Finder, SystemUIServer, cfprefsd are restarted in macos.sh)
