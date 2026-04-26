# Add a New Profile

Example: adding a `client` profile alongside `work` and `personal`.

## 1. Create the Directory Structure

```bash
mkdir -p profiles/client/apps
mkdir -p profiles/client/dotfiles
mkdir -p profiles/client/macos
```

## 2. Create the Required Files

**App lists** — copy from work as a starting point and trim:
```bash
cp profiles/work/apps/brew-formulae.txt   profiles/client/apps/
cp profiles/work/apps/brew-casks.txt      profiles/client/apps/
cp profiles/work/apps/direct-downloads.yaml profiles/client/apps/
```

Edit each file for the client profile's actual needs.

**Dotfiles:**
```bash
# Create a profile-specific zshrc.local
cat > profiles/client/dotfiles/.zshrc.local << 'EOF'
# .zshrc.local — client profile zsh config.
# TODO: Add client-specific PATH, aliases, env vars
EOF
```

**macOS defaults:**
```bash
# Create a profile-specific defaults file (can be mostly TODOs)
cat > profiles/client/macos/defaults.sh << 'EOF'
#!/usr/bin/env bash
# Client-profile macOS overrides.
# TODO: Add client-specific defaults write overrides here
EOF
```

## 3. Update install.sh

Two places to edit in `scripts/install.sh`:

**a) Profile validation** (in `main()`):
```bash
# BEFORE:
if [[ "$PROFILE" != "work" && "$PROFILE" != "personal" ]]; then

# AFTER:
if [[ "$PROFILE" != "work" && "$PROFILE" != "personal" && "$PROFILE" != "client" ]]; then
```

**b) Interactive menu** (in `choose_profile()`):
```bash
# Add the new option to the display and case statement:
printf "  ${BOLD}3)${RESET} client    — client machine setup\n\n"
printf "Choice [1/2/3]: "
# ...
case "$choice" in
  1|work)     echo "work" ;;
  2|personal) echo "personal" ;;
  3|client)   echo "client" ;;    # ADD THIS
```

## 4. Update validate.sh

In `check_structure()`, add the new profile's required files to the
`required_files` array:

```bash
"profiles/client/apps/brew-formulae.txt"
"profiles/client/apps/brew-casks.txt"
"profiles/client/apps/direct-downloads.yaml"
"profiles/client/dotfiles/.zshrc.local"
"profiles/client/macos/defaults.sh"
```

## 5. Update GitHub Actions

In `.github/workflows/validate.yml`, add a dry-run step for the new profile:

```yaml
- name: Dry run client profile
  run: bash scripts/install.sh client --dry-run --skip-macos-defaults
```

## 6. Test

```bash
bash scripts/validate.sh
./scripts/install.sh client --dry-run
```

## Checklist

- [ ] `profiles/client/apps/brew-formulae.txt` created
- [ ] `profiles/client/apps/brew-casks.txt` created
- [ ] `profiles/client/apps/direct-downloads.yaml` created
- [ ] `profiles/client/dotfiles/.zshrc.local` created
- [ ] `profiles/client/macos/defaults.sh` created
- [ ] `install.sh` profile validation updated
- [ ] `install.sh` menu updated
- [ ] `validate.sh` required_files updated
- [ ] `.github/workflows/validate.yml` dry-run step added
- [ ] `bash scripts/validate.sh` passes
- [ ] `./scripts/install.sh client --dry-run` runs without error
