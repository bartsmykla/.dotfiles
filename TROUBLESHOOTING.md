# Troubleshooting

Quick reference for common issues and debugging techniques.

## Quick Diagnostics

```bash
task test           # Run all tests
task lint           # Run all linters
chezmoi verify      # Verify chezmoi state
chezmoi doctor      # Check chezmoi setup
```

## Chezmoi Issues

### Files Not Syncing

**Check state:**

```bash
chezmoi diff                # See pending changes
chezmoi status              # Check modified files
```

**Apply changes:**

```bash
chezmoi apply --verbose     # Apply with detailed output
```

**Fix out-of-sync file:**

```bash
chezmoi forget ~/.config/problematic-file
chezmoi add ~/.config/problematic-file
```

### Encrypted Files Not Decrypting

**Check age key:**

```bash
ls -la ~/.config/chezmoi/key.txt        # Should exist with 600 perms
age --decrypt --identity ~/.config/chezmoi/key.txt < chezmoi/encrypted_test.age
```

**Re-add encrypted file:**

```bash
chezmoi forget ~/.config/problematic-file
chezmoi add --encrypt ~/.config/problematic-file
```

## Git Filter Issues

### Files Not Encrypting/Decrypting

**Check git filters:**

```bash
git config filter.age.clean     # Should show encryption command
git config filter.age.smudge    # Should show decryption command
```

**Re-configure filters:**

```bash
git config filter.age.clean "~/.git/age-clean.sh"
git config filter.age.smudge "age --decrypt --identity ~/.config/chezmoi/key.txt 2>/dev/null || cat"
```

**Force re-encryption:**

```bash
git rm --cached path/to/file
git add path/to/file
```

## Test Failures

### ShellSpec Tests Failing

**Run specific test:**

```bash
shellspec spec/specific_test_spec.sh
```

**Verbose output:**

```bash
shellspec --format documentation spec/
```

### Fish Syntax Errors

**Check fish config:**

```bash
fish --no-execute ~/.config/fish/config.fish
```

## Tool Issues

### mise Tools Not Available

**Check mise:**

```bash
mise doctor                 # Diagnose mise issues
mise list                   # Show installed tools
mise install                # Install missing tools
```

### Task Command Not Found

**Install dependencies:**

```bash
brew install go-task
mise install
```

## CI/CD Issues

### GitHub Actions Failing

**Check workflow locally:**

```bash
actionlint .github/workflows/test.yaml
```

**Test age decryption:**

```bash
age --decrypt --identity ~/.config/age/ci-key.txt < CLAUDE.md
```

## System Architecture

The dotfiles system uses:

- **chezmoi**: Manages dotfiles, applies templates, encrypts secrets
- **age**: Encrypts files (both chezmoi-managed and git-filter managed)
- **Task**: Runs tests and linters
- **mise**: Manages tool versions

### Two Encryption Systems

1. **Chezmoi encryption** (`encrypted_*.age` in source):
   - Managed by chezmoi
   - Use `chezmoi add --encrypt` to add
   - Decrypt on `chezmoi apply`

2. **Git filter encryption** (via `.gitattributes`):
   - Transparent encryption on commit
   - Files: `CLAUDE.md`, `secrets/**`, `todos/**`
   - Configured in `.git/age-clean.sh` and `.git/age-smudge.sh`

## Getting Help

See full documentation:

- [CONTRIBUTING.md](CONTRIBUTING.md) - Development workflow
- [TESTING.md](TESTING.md) - Testing approach
- [README.md](README.md) - Quick start and overview
