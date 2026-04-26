# Add an App

Use this decision tree to find the right file to edit.

## Decision Tree

```
Is the app on Homebrew?
    │
    ├─ YES → Is it a CLI tool (no .app bundle)?
    │            ├─ YES → brew-formulae.txt
    │            └─ NO  → brew-casks.txt
    │
    └─ NO  → direct-downloads.yaml (DMG or PKG download)

For any file above:
    Is this app needed on ALL profiles (work AND personal)?
        ├─ YES → profiles/shared/apps/<file>
        └─ NO  → profiles/work/apps/<file>  OR  profiles/personal/apps/<file>
```

## Adding a Homebrew Formula

**File:** `profiles/shared/apps/brew-formulae.txt` (or `profiles/{work,personal}/apps/`)

1. Find the formula name: `brew search <name>` or https://formulae.brew.sh
2. Add one line with the formula name:
   ```
   nvim
   ```
3. Test: `./scripts/install.sh work --dry-run` — look for "installing: nvim" in the output
4. Commit and push

## Adding a Homebrew Cask

**File:** `profiles/shared/apps/brew-casks.txt` (or `profiles/{work,personal}/apps/`)

1. Find the cask name: `brew search --cask <name>` or https://formulae.brew.sh/cask/
2. Add one line with the cask name (note: cask names use hyphens, not spaces):
   ```
   visual-studio-code
   ```
3. Test: `./scripts/install.sh work --dry-run`
4. Commit and push

**Cask name vs app name:** `visual-studio-code` installs `Visual Studio Code.app`.
These differ — use `brew info --cask <name>` to confirm what it installs.

## Adding a Direct Download App

**File:** `profiles/shared/apps/direct-downloads.yaml` (or profile-specific)

Add a block under `apps:`:

```yaml
apps:
  - name: "AppName"
    url: "https://example.com/download/AppName.dmg"
    type: dmg
    app_name: "AppName.app"
    checksum: "sha256:abc123..."
    post_install: ""
```

**Field reference:**

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Display name (used in logs) |
| `url` | yes | Direct download URL (must be a file, not a landing page) |
| `type` | yes | `dmg` or `pkg` |
| `app_name` | yes | Filename as it appears in /Applications (used for skip check) |
| `checksum` | no | `sha256:hexdigest` or `sha512:hexdigest` |
| `post_install` | no | Shell command to run after install |

**Getting the checksum:**
```bash
curl -fsSL "https://example.com/App.dmg" -o /tmp/app.dmg
shasum -a 256 /tmp/app.dmg
```

3. Test: `./scripts/install.sh work --dry-run`
4. Commit and push

## Testing Before Committing

```bash
# Check format and structure
bash scripts/validate.sh

# See what would happen without making changes
./scripts/install.sh work --dry-run

# Verbose mode shows every command
./scripts/install.sh work --dry-run --verbose
```

## Reminder: Shared vs Profile-Specific

- **shared** = installed regardless of whether you run `work` or `personal`
- **work/personal** = installed only for that profile

When in doubt, put it in `shared/` and remove it later if you find it's not needed on one machine type.
