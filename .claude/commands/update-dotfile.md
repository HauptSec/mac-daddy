# Update a Dotfile

## How Shared vs Profile-Specific Dotfiles Work

```
profiles/shared/dotfiles/     → symlinked to $HOME for ALL profiles
profiles/work/dotfiles/       → symlinked to $HOME only for the work profile
profiles/personal/dotfiles/   → symlinked to $HOME only for the personal profile
```

The symlink target is the absolute path to the file in your local repo clone.
Edits to files in the repo take effect immediately in the next shell session —
no re-run of install.sh required.

## Symlink Naming Convention

The filename in the repo becomes the filename in `$HOME`. Examples:

| Repo path | $HOME symlink |
|-----------|---------------|
| `profiles/shared/dotfiles/.zshrc` | `~/.zshrc` |
| `profiles/shared/dotfiles/.gitconfig` | `~/.gitconfig` |
| `profiles/work/dotfiles/.zshrc.local` | `~/.zshrc.local` |

Rules:
- Files must start with `.` (they are hidden dotfiles)
- No subdirectory nesting — only top-level files are symlinked
- For nested config (e.g. `~/.config/nvim/`), add an explicit step to install.sh

## Modifying an Existing Dotfile

Just edit the file in the repo:
```bash
# Example: add an alias to the shared zshrc
$EDITOR profiles/shared/dotfiles/.zshrc
```

The change is live immediately. Open a new terminal or `source ~/.zshrc` to apply.

## Adding a New Dotfile

1. Create the file in the appropriate dotfiles directory:
   ```bash
   # Shared (all profiles):
   touch profiles/shared/dotfiles/.newsettings

   # Work-only:
   touch profiles/work/dotfiles/.newsettings
   ```

2. Add your config to the file.

3. Run the dotfiles step to create the symlink:
   ```bash
   # Full install (smart diff will only create the new symlink)
   ./scripts/install.sh work

   # Or test first:
   ./scripts/install.sh work --dry-run
   ```

## How .zshrc.local Sourcing Works

`profiles/shared/dotfiles/.zshrc` ends with:
```zsh
[[ -f "${HOME}/.zshrc.local" ]] && source "${HOME}/.zshrc.local"
```

`~/.zshrc.local` is a symlink created by the profile-specific dotfiles step:
- `work` profile → symlinks `profiles/work/dotfiles/.zshrc.local`
- `personal` profile → symlinks `profiles/personal/dotfiles/.zshrc.local`

This means:
- Only one `.zshrc.local` can be active at a time (the current profile's)
- Profile-specific config goes in the profile's `.zshrc.local`
- Shared config goes directly in `.zshrc`

## Testing Symlinks Without Re-Running Full Install

Check current symlink state:
```bash
ls -la ~/.zshrc ~/.gitconfig ~/.zshrc.local 2>/dev/null
```

Verify a symlink points to the repo:
```bash
readlink ~/.zshrc
# Should show: /path/to/mac-daddy/profiles/shared/dotfiles/.zshrc
```

Manually test the dotfiles step only (dry run):
```bash
./scripts/install.sh work --dry-run 2>&1 | grep -A 20 "Shared Dotfiles"
```

Re-run just the symlink step:
```bash
# Re-running install.sh is idempotent — already-linked files are skipped
./scripts/install.sh work --skip-macos-defaults
```
