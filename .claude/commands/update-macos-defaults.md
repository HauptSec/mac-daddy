# Update macOS Defaults

## Finding the Right `defaults` Key

The best way to find the correct domain and key for a preference:

**Method 1 — Diff before/after:**
```bash
# Snapshot current defaults
defaults read > /tmp/before.txt

# Change the setting in System Settings UI

# Compare
defaults read > /tmp/after.txt
diff /tmp/before.txt /tmp/after.txt
```

**Method 2 — Read a specific domain:**
```bash
# List all keys for an app
defaults read com.apple.dock
defaults read com.apple.finder
defaults read NSGlobalDomain

# Read a specific key
defaults read com.apple.dock autohide
```

**Method 3 — Use `defaultseditor` or community scripts:**
Search https://macos-defaults.com for common preferences with documented keys.

## Which File to Edit

| Scope | File |
|-------|------|
| All profiles | `profiles/shared/macos/defaults.sh` |
| Work only | `profiles/work/macos/defaults.sh` |
| Personal only | `profiles/personal/macos/defaults.sh` |

Profile-specific defaults run AFTER shared defaults, so profile files can
override any shared setting by writing to the same domain+key.

## Testing a Single defaults Command

Before adding to a file, test the command directly:
```bash
# Test write (takes effect immediately after process restart)
defaults write com.apple.dock autohide-delay -float 0

# Restart the affected process
killall Dock

# Verify it worked
defaults read com.apple.dock autohide-delay

# Revert if needed
defaults delete com.apple.dock autohide-delay
killall Dock
```

## killall Commands by System Area

| Area changed | killall command |
|--------------|-----------------|
| Dock settings | `killall Dock` |
| Finder settings | `killall Finder` |
| Menu bar / status | `killall SystemUIServer` |
| Most preferences | `killall cfprefsd` |
| Notification Center | `killall NotificationCenter` |

`apply_macos_defaults()` in `macos.sh` automatically runs all four restarts
after sourcing each defaults file.

## Preferences That Require Logout or Restart

These settings cannot be applied by process restart alone:

- **AppleFontSmoothing** (subpixel rendering) — requires logout
- **HiDPI modes** — requires logout
- **Startup sound** (`nvram SystemAudioVolume`) — applies at next boot
- **FileVault / SIP** — cannot be changed via `defaults write`
- **Login items** — requires GUI or `sfltool`

Mark these with a comment in the defaults file:
```bash
# Requires logout to take effect
defaults write NSGlobalDomain AppleFontSmoothing -int 1
```

## Dry-Running Defaults Changes

```bash
# See which defaults files would be sourced without executing them
./scripts/install.sh work --dry-run --skip-macos-defaults
# (Note: --skip-macos-defaults means defaults step shows as skipped in dry-run)

# To see the dry-run of the defaults step specifically, omit --skip-macos-defaults:
./scripts/install.sh work --dry-run
# Output will show: [DRY-RUN] Would source: /path/to/defaults.sh
```

## Writing Correct defaults write Syntax

```bash
# Boolean
defaults write com.apple.dock autohide -bool true

# Integer
defaults write com.apple.dock tilesize -int 48

# Float
defaults write com.apple.dock autohide-delay -float 0

# String
defaults write com.apple.dock orientation -string "bottom"

# Array
defaults write NSGlobalDomain AppleLanguages -array "en-US" "en"

# Dict
defaults write com.apple.finder FXInfoPanesExpanded -dict \
  General -bool true \
  OpenWith -bool true

# currentHost (for per-device prefs, not synced via iCloud)
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

# Global domain shorthand
defaults write -g KeyRepeat -int 2   # same as NSGlobalDomain
```
