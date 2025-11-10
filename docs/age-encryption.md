# Age Encryption in Dotfiles

This repository uses [age](https://age-encryption.org/) for encrypting sensitive files. Age is a modern, simple file encryption tool that's secure and easy to use.

## Overview

We use two different age encryption approaches:

1. **Chezmoi-managed files**: Files in your home directory managed by chezmoi (like `~/.claude`, `~/.config/fish/conf.d/abbreviations.fish`)
2. **Repository files**: Files that stay in `.dotfiles` directory (like `Brewfile`, `CLAUDE.md`, `todos/`)

## How It Works

### Chezmoi-Managed Files

Chezmoi has built-in age encryption support. When you add files with `chezmoi add --encrypt`, they are:

- Stored as `.age` files in `chezmoi/` source directory
- Automatically decrypted when applied to your home directory
- Encrypted using the age recipient configured in `~/.config/chezmoi/chezmoi.toml`

### Repository Files (Git Filters)

For files that stay in the `.dotfiles` directory, we use Git clean/smudge filters for transparent encryption:

- **Clean filter**: Encrypts files when committing to git
- **Smudge filter**: Decrypts files when checking out from git
- Files appear decrypted in your working directory
- Files are stored encrypted in git history

## Setup

### 1. Age Key Location

The age encryption key is stored at:

```
~/.config/chezmoi/key.txt
```

**Important**: This key file is private and must be kept secure. Never commit it to git.

### 2. Chezmoi Configuration

Configuration in `~/.config/chezmoi/chezmoi.toml`:

```toml
encryption = "age"

[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1c459u9ehvrjrsh6v2sun69mw3p6apuku8cjh9q8eeax2etr439pshvnn4z"
```

### 3. Git Filters

Git filters are configured in `.git/config`:

```ini
[filter "age"]
    clean = /path/to/.dotfiles/.git/age-clean.sh
    smudge = /path/to/.dotfiles/.git/age-smudge.sh
    required = true
```

## Usage

### Adding Encrypted Files to Chezmoi

To add a file from your home directory with encryption:

```bash
chezmoi add --encrypt ~/.config/secret-file
```

This will:
- Copy the file to chezmoi source directory
- Encrypt it with age
- Store it as `chezmoi/private_dot_config/encrypted_secret-file.age`

### Viewing Encrypted Files

To see the decrypted content of a chezmoi-managed file:

```bash
chezmoi cat ~/.config/secret-file
```

### Editing Encrypted Files

To edit an encrypted file managed by chezmoi:

```bash
chezmoi edit ~/.config/secret-file
```

This will:
- Decrypt the file temporarily
- Open it in your editor (configured in chezmoi.toml)
- Re-encrypt it when you save

### Applying Changes

To apply chezmoi changes to your home directory:

```bash
chezmoi apply
```

Or to see what would change first:

```bash
chezmoi diff
```

## Encrypted File Patterns

The following patterns are encrypted (configured in `.gitattributes`):

### Chezmoi-Managed (Built-in age encryption)

- `~/.claude/**` → `chezmoi/private_dot_claude/encrypted_*.age`
- `~/.config/fish/conf.d/abbreviations.fish`
- `~/.config/k9s/config.yaml`
- `~/.config/exercism/user.json`

### Repository Files (Git filter encryption)

- `Brewfile` - Homebrew packages list
- `CLAUDE.md` - Claude Code instructions
- `secrets/**` - API tokens and credentials
- `todos/**` - Personal todo files
- `helper_scripts/**/*.secret.bash` - Secret helper scripts
- `helpers/**/*.secret.*` - Secret helper configurations

## Manual Encryption/Decryption

If you need to manually encrypt or decrypt files (for repository files, not chezmoi):

### Encrypt a File

```bash
age --encrypt --recipient age1c459u9ehvrjrsh6v2sun69mw3p6apuku8cjh9q8eeax2etr439pshvnn4z \
    --output encrypted-file.age plaintext-file
```

### Decrypt a File

```bash
age --decrypt --identity ~/.config/chezmoi/key.txt \
    --output plaintext-file encrypted-file.age
```

## New Machine Setup

To use these encrypted dotfiles on a new machine:

1. **Copy your age key** to the new machine:
   ```bash
   mkdir -p ~/.config/chezmoi
   # Copy key.txt to ~/.config/chezmoi/key.txt
   chmod 600 ~/.config/chezmoi/key.txt
   ```

2. **Install age** via mise:
   ```bash
   mise install age
   ```

3. **Clone the repository**:
   ```bash
   git clone https://github.com/bartsmykla/.dotfiles ~/Projects/github.com/bartsmykla/.dotfiles
   cd ~/Projects/github.com/bartsmykla/.dotfiles
   ```

4. **Initialize chezmoi**:
   ```bash
   chezmoi init
   ```

5. **Files will automatically decrypt** when you check them out or apply chezmoi

## Security Notes

### Do

- ✅ Keep `~/.config/chezmoi/key.txt` private and secure
- ✅ Back up your age key to a secure location (password manager, encrypted USB)
- ✅ Use different age keys for different security domains if needed
- ✅ Review what files are encrypted before committing

### Don't

- ❌ Never commit `~/.config/chezmoi/key.txt` to git
- ❌ Don't share your private age key
- ❌ Don't store age key in cloud storage without encryption
- ❌ Don't add files with secrets without encryption

## Troubleshooting

### Decryption Failed

If decryption fails when checking out or applying files:

1. Check that your age key exists:
   ```bash
   ls -la ~/.config/chezmoi/key.txt
   ```

2. Verify the key permissions (should be 600):
   ```bash
   chmod 600 ~/.config/chezmoi/key.txt
   ```

3. Check that age is installed:
   ```bash
   age --version
   ```

### Files Not Encrypting

If files aren't being encrypted:

1. Check `.gitattributes` has the correct patterns
2. Verify git filter configuration:
   ```bash
   git config filter.age.clean
   git config filter.age.smudge
   ```

3. Force git to re-apply filters:
   ```bash
   git rm --cached -r .
   git reset --hard HEAD
   ```

### Viewing Git Filter Status

To see which files git will encrypt:

```bash
git check-attr filter -- **/secret-file
```

## Migration from git-crypt

This repository was migrated from git-crypt to age. The migration:

1. Created an age encryption key
2. Configured chezmoi to use age for managed files
3. Set up git filters for repository files
4. Removed git-crypt configuration

Old git-crypt encrypted history remains in git history but new commits use age.
