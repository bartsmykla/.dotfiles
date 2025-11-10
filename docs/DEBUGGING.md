# Debugging Guide

This guide helps troubleshoot common issues with the dotfiles setup.

## Quick Diagnostics

Run these commands to diagnose issues:

```bash
task test           # Run all tests
task lint           # Run all linters
chezmoi verify      # Verify chezmoi state
chezmoi doctor      # Check chezmoi setup
```

## Chezmoi Issues

### Files Not Syncing

**Symptoms**: Changes in `chezmoi/` source don't appear in `~/`

**Diagnosis**:

```bash
chezmoi verify                      # Check for inconsistencies
chezmoi diff                        # See what would change
chezmoi status                      # Check modified files
```

**Solutions**:

1. Apply changes explicitly:

   ```bash
   chezmoi apply --verbose
   ```

2. Force re-add if file is out of sync:

   ```bash
   chezmoi forget ~/.config/problematic-file
   chezmoi add ~/.config/problematic-file
   ```

3. Check for conflicts:

   ```bash
   chezmoi diff ~/.config/problematic-file
   ```

### Encrypted Files Not Decrypting

**Symptoms**: Encrypted files show garbled content or fail to apply

**Diagnosis**:

```bash
ls -la ~/.config/chezmoi/key.txt    # Check key exists
age --version                        # Check age installed
chezmoi cat ~/.config/encrypted-file # Try to decrypt
```

**Solutions**:

See [AGE-ENCRYPTION.md](AGE-ENCRYPTION.md#new-machine-setup) for complete key setup.

Quick checks:

```bash
ls -la ~/.config/chezmoi/key.txt     # Verify exists
chmod 600 ~/.config/chezmoi/key.txt  # Fix permissions
age --version                        # Verify installed
mise install age                     # Install if missing
```

Verify encryption configuration:

```bash
chezmoi data | jq '.age'
```

### Chezmoi Template Errors

**Symptoms**: Errors about undefined variables or template syntax

**Diagnosis**:

```bash
chezmoi execute-template < chezmoi/.chezmoi.toml.tmpl
chezmoi data | jq .
```

**Solutions**:

1. Check template syntax in `.chezmoi.toml.tmpl`
2. Verify all template variables are defined
3. Test template rendering:

   ```bash
   chezmoi execute-template '{{ .chezmoi.os }}'
   ```

## Age Encryption Issues

### Git Filter Not Working

**Symptoms**: Files not encrypted/decrypted on git operations

**Diagnosis**:

```bash
git check-attr filter -- Brewfile    # Check filter applies
git config filter.age.clean          # Check clean filter
git config filter.age.smudge         # Check smudge filter
```

**Solutions**:

1. Check filter scripts exist and are executable:

   ```bash
   ls -la .git/age-clean.sh .git/age-smudge.sh
   chmod +x .git/age-clean.sh .git/age-smudge.sh
   ```

2. Verify git config:

   ```bash
   git config filter.age.required
   ```

3. Re-apply filters:

   ```bash
   git rm --cached -r .
   git reset --hard HEAD
   ```

### Age Key Issues

**Symptoms**: "no identity found" or decryption errors

**Solutions**:

See [AGE-ENCRYPTION.md](AGE-ENCRYPTION.md#new-machine-setup) for detailed key setup instructions.

Quick check:

```bash
ls -la ~/.config/chezmoi/key.txt    # Verify key exists
chmod 600 ~/.config/chezmoi/key.txt # Fix permissions
head -1 ~/.config/chezmoi/key.txt   # Check format (AGE-SECRET-KEY-)
```

## Fish Shell Issues

### Fish Config Not Loading

**Symptoms**: Fish starts but custom functions/aliases don't work

**Diagnosis**:

```bash
fish -n ~/.config/fish/config.fish   # Check syntax
fish -c "echo 'test'"                # Test fish loads
```

**Solutions**:

1. Check for syntax errors:

   ```bash
   find chezmoi/private_dot_config/fish -name "*.fish" -exec fish -n {} \;
   ```

2. Reload fish config:

   ```bash
   source ~/.config/fish/config.fish
   ```

3. Check function directory:

   ```bash
   ls ~/.config/fish/functions/
   ```

### Functions Not Found

**Symptoms**: `command not found` for custom functions

**Diagnosis**:

```bash
functions | grep function-name       # Check if loaded
type function-name                   # Check function location
```

**Solutions**:

1. Verify function file exists:

   ```bash
   ls ~/.config/fish/functions/function-name.fish
   ```

2. Source function manually:

   ```bash
   source ~/.config/fish/functions/function-name.fish
   ```

3. Check file permissions:

   ```bash
   chmod 644 ~/.config/fish/functions/*.fish
   ```

## Task/Testing Issues

### Task Command Not Found

**Symptoms**: `task: command not found`

**Solutions**:

```bash
mise install task                    # Install task
mise reshim                          # Refresh shims
which task                           # Verify in PATH
```

### Linter Failures

**Symptoms**: Tests fail with linter errors

**Diagnosis**:

```bash
task lint:shell                      # Run shellcheck
task lint:markdown                   # Run markdownlint
task lint:taskfile                   # Validate Taskfile
```

**Solutions**:

1. Fix shellcheck issues:

   ```bash
   shellcheck path/to/script.sh
   ```

2. Fix markdown issues:

   ```bash
   markdownlint --fix file.md
   ```

3. Update linter versions:

   ```bash
   mise use shellcheck@latest
   mise install
   ```

### Tests Pass Locally But Fail in CI

**Diagnosis**:

1. Check CI logs for specific errors
2. Compare tool versions:

   ```bash
   mise list
   ```

**Solutions**:

1. Pin tool versions in `mise` config
2. Update CI workflow to match local environment
3. Test in Docker container matching CI:

   ```bash
   docker run -it ubuntu:24.04 bash
   ```

## Homebrew Issues

### Brewfile Validation Fails

**Symptoms**: `brew bundle check` fails

**Diagnosis**:

```bash
brew bundle check --verbose --file=Brewfile
```

**Solutions**:

1. Install missing packages:

   ```bash
   brew bundle install --file=Brewfile
   ```

2. Update outdated packages:

   ```bash
   brew update && brew upgrade
   ```

3. Check for conflicts:

   ```bash
   brew doctor
   ```

## Git Issues

### Commit Signing Fails

**Symptoms**: Commits fail with GPG errors

**Diagnosis**:

```bash
git config --get user.signingkey
gpg --list-secret-keys
```

**Solutions**:

1. Verify GPG key exists:

   ```bash
   gpg --list-secret-keys --keyid-format LONG
   ```

2. Set signing key:

   ```bash
   git config --global user.signingkey YOUR_KEY_ID
   ```

3. Test GPG signing:

   ```bash
   echo "test" | gpg --clearsign
   ```

### Submodule Issues

**Symptoms**: Missing vim plugins or submodule errors

**Solutions**:

```bash
git submodule update --init --recursive
git submodule foreach git pull origin master
```

## Environment Issues

### Environment Variables Not Set

**Symptoms**: `$DOTFILES_PATH` or other variables undefined

**Diagnosis**:

```bash
echo $DOTFILES_PATH
echo $PROJECTS_PATH
```

**Solutions**:

1. Reload fish config:

   ```bash
   source ~/.config/fish/config.fish
   ```

2. Check variable definitions:

   ```bash
   grep DOTFILES_PATH ~/.config/fish/config.fish
   ```

### PATH Issues

**Symptoms**: Commands not found even after installation

**Solutions**:

```bash
echo $PATH                           # Check current PATH
mise reshim                          # Refresh mise shims
hash -r                              # Refresh command cache (bash)
```

## Diagnostic Commands

### System Information

```bash
uname -a                             # OS info
sw_vers                              # macOS version
fish --version                       # Fish version
mise --version                       # Mise version
chezmoi --version                    # Chezmoi version
age --version                        # Age version
```

### Check Tool Installations

```bash
which fish shellcheck markdownlint task chezmoi age
mise list                            # Installed tools
brew list                            # Homebrew packages
```

### Chezmoi State

```bash
chezmoi status                       # Modified files
chezmoi verify                       # Verify consistency
chezmoi diff                         # See differences
chezmoi data                         # Template data
chezmoi doctor                       # Health check
```

### Git State

```bash
git status                           # Working tree status
git diff                             # Unstaged changes
git diff --cached                    # Staged changes
git log --oneline -10                # Recent commits
git remote -v                        # Remotes
```

## Getting Help

If issues persist:

1. Check [TESTING.md](../TESTING.md) for testing guidelines
2. Check [docs/AGE-ENCRYPTION.md](AGE-ENCRYPTION.md) for encryption issues
3. Run diagnostics and collect output:

   ```bash
   task test 2>&1 | tee debug.log
   chezmoi doctor 2>&1 | tee -a debug.log
   ```

4. Open an issue with debug logs (sanitize secrets first)
