# Architecture

This document describes the architecture, design decisions, and component interactions of the dotfiles system.

## Overview

The dotfiles system is built on four core components:

1. **[chezmoi](https://chezmoi.io)**: Dotfile management and deployment
2. **[age](https://age-encryption.org/)**: File encryption
3. **[Taskfile](https://taskfile.dev)**: Task automation and testing
4. **[mise](https://mise.jdx.dev/)**: Tool version management

## System Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                    User's Home Directory                    │
│  ~/.config/fish/       ~/.vimrc       ~/.config/k9s/        │
└────────────────────────────┬────────────────────────────────┘
                             │
                             │ chezmoi apply
                             │
┌────────────────────────────▼────────────────────────────────┐
│              Chezmoi Source Directory                       │
│                  ~/Projects/.../chezmoi/                    │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Plain Files           Encrypted Files (.age)         │   │
│  │ • config.fish        • encrypted_abbreviations.fish  │   │
│  │ • .vimrc             • encrypted_config.yaml         │   │
│  └──────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────┘
                             │
                             │ git commit/push
                             │
┌────────────────────────────▼────────────────────────────────┐
│                    Git Repository                           │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Git Clean Filter (encrypt)                           │   │
│  │ • Brewfile          → encrypted                      │   │
│  │ • CLAUDE.md         → encrypted                      │   │
│  │ • secrets/**        → encrypted                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Git Smudge Filter (decrypt)                          │   │
│  │ • encrypted         → plaintext (working directory)  │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Components

### Chezmoi

**Purpose**: Manages dotfiles declaratively with templates and encryption.

**Key Concepts**:

- **Source directory**: `~/Projects/.../chezmoi/` contains dotfile sources
- **Target directory**: `~/` where files are deployed
- **Naming convention**:
  - `dot_` prefix → `.` in target (`dot_vimrc` → `.vimrc`)
  - `private_` prefix → private file (restrictive permissions)
  - `encrypted_` prefix + `.age` suffix → encrypted file
- **Templates**: `.tmpl` suffix enables Go templating

**Configuration**:

- **Global**: `~/.config/chezmoi/chezmoi.toml`
- **Template**: `chezmoi/.chezmoi.toml.tmpl` (version-controlled)
- **Ignore**: `chezmoi/.chezmoiignore` (exclude patterns)

**Encryption Integration**:

```toml
encryption = "age"

[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1c459u9ehvrjrsh6v2sun69mw3p6apuku8cjh9q8eeax2etr439pshvnn4z"
```

### Age Encryption

**Purpose**: Encrypts sensitive files using modern, simple cryptography.

**Two Encryption Layers**:

1. **Chezmoi-managed files**: Encrypted by chezmoi
   - Files in `~/` (e.g., `~/.claude/**`, `~/.config/k9s/config.yaml`)
   - Stored as `.age` files in chezmoi source
   - Automatically decrypted by chezmoi when applied

2. **Repository files**: Encrypted by git filters
   - Files that stay in repository (e.g., `Brewfile`, `CLAUDE.md`)
   - Encrypted on `git add` (clean filter)
   - Decrypted on `git checkout` (smudge filter)

**Key Management**:

- **Private key**: `~/.config/chezmoi/key.txt` (never committed)
- **Public key**: Embedded in config, used for encryption
- **Backup**: Stored in 1Password (UUID: `dyhxf4wgavxqwqt23wbsl5my2m`)

**Git Filters**:

```bash
# .git/age-clean.sh (encrypt on commit)
age --encrypt --recipient <public-key> --armor

# .git/age-smudge.sh (decrypt on checkout)
age --decrypt --identity ~/.config/chezmoi/key.txt
```

### Taskfile

**Purpose**: Automates testing, linting, and common development tasks.

**Task Categories**:

1. **Testing**: `test`, `test:fish`, `test:brewfile`, `test:shellspec`
2. **Linting**: `lint`, `lint:shell`, `lint:markdown`, `lint:taskfile`
3. **Aliases**: `check` (alias for `lint`)

**Task Structure**:

```yaml
tasks:
  test:fish:
    desc: Test Fish configuration loads
    dir: '{{.G_DOTFILES}}'
    sources:
      - chezmoi/private_dot_config/fish/**/*.fish
    cmds:
      - fish -c "echo 'Fish config OK'"
```

**Features**:

- **Caching**: `sources` and `generates` for smart re-runs
- **Variables**: Global variables like `G_DOTFILES`
- **Dependencies**: `deps` for task ordering
- **Validation**: Schema validation via `check-jsonschema`

### Mise

**Purpose**: Manages tool versions consistently across environments.

**Managed Tools**:

- `age` 1.2.1 (encryption)
- `chezmoi` 2.67.0 (dotfile management)
- `task` (latest)
- `shellcheck` (latest)
- `markdownlint-cli` (latest)

**Benefits**:

- **Reproducibility**: Same versions everywhere (local, CI)
- **Isolation**: Tools in `~/.local/share/mise/installs/`
- **Activation**: Automatic via `.mise.toml` detection

## Design Decisions

### Why Chezmoi?

**Alternatives considered**: GNU Stow, yadm, rcm

**Chosen because**:

- Built-in encryption support (age, GPG)
- Powerful templating (OS-specific configs)
- Excellent documentation and community
- Active development and maintenance
- Handles complex scenarios (multi-machine, secrets)

### Why Age over GPG/git-crypt?

**Previous solution**: git-crypt with GPG

**Migrated to age because**:

- **Simplicity**: Single key file vs GPG keyring complexity
- **Modern**: Designed for the 2020s, simple spec
- **Performance**: Faster encryption/decryption
- **Portability**: Easier to backup/restore (single file)
- **Compatibility**: Works seamlessly with chezmoi

### Why Taskfile over Make?

**Previous solution**: Makefile

**Migrated to Taskfile because**:

- **YAML syntax**: More readable than Make syntax
- **Cross-platform**: Better Windows support
- **Smart caching**: Sources/generates tracking
- **Dependencies**: Clearer task dependencies
- **Schema validation**: JSON schema for validation
- **Go templating**: Variable interpolation

### Why Mise over asdf?

**Alternatives considered**: asdf, rtx

**Chosen because**:

- **Performance**: Written in Rust, faster than asdf
- **Compatibility**: Drop-in asdf replacement
- **Features**: Better activation, parallel installs
- **Backend**: asdf is the predecessor, mise is the evolution

## Data Flow

### Applying Dotfiles

```text
1. User runs: chezmoi apply
2. Chezmoi reads source directory
3. For encrypted files (.age):
   a. Decrypt using age identity key
   b. Apply to target location
4. For plain files:
   a. Apply directly to target location
5. Set correct permissions (private_* files)
```

### Committing Changes

```text
1. User modifies files in chezmoi/ source
2. User runs: git add Brewfile CLAUDE.md
3. Git clean filter (.git/age-clean.sh):
   a. Read plaintext from working directory
   b. Encrypt using age public key
   c. Store encrypted in git
4. User commits and pushes
```

### Checking Out Repository

```text
1. User runs: git clone / git checkout
2. Git smudge filter (.git/age-smudge.sh):
   a. Read encrypted from git
   b. Decrypt using age identity key
   c. Write plaintext to working directory
3. Files appear decrypted locally
```

### Running Tests

```text
1. User runs: task test
2. Taskfile checks sources (cached):
   - chezmoi/private_dot_config/fish/**/*.fish
   - Taskfile.yaml
3. If changed, run test commands:
   - fish -n (syntax check)
   - fish -c "echo 'test'" (load check)
4. Report results
```

## File Organization

### Repository Structure

```text
.dotfiles/
├── chezmoi/                       # Chezmoi source directory
│   ├── .chezmoi.toml.tmpl         # Chezmoi config (templated)
│   ├── .chezmoiignore             # Files to ignore
│   ├── dot_vimrc                  # Plain file → ~/.vimrc
│   ├── private_dot_config/        # Maps to ~/.config/
│   │   ├── fish/
│   │   │   ├── config.fish
│   │   │   └── functions/
│   │   └── mise/
│   │       └── config.toml
│   └── private_dot_claude/        # Encrypted
│       └── encrypted_*.age
├── docs/                          # Documentation
│   ├── AGE-ENCRYPTION.md
│   └── DEBUGGING.md
├── .github/workflows/             # CI/CD
│   └── test.yaml
├── .git/                          # Git metadata
│   ├── age-clean.sh               # Encrypt filter
│   └── age-smudge.sh              # Decrypt filter
├── .gitattributes                 # Git filter mappings
├── Taskfile.yaml                  # Task automation
├── Brewfile                       # Homebrew (encrypted)
├── CLAUDE.md                      # Instructions (encrypted)
├── secrets/                       # Secrets (encrypted)
└── todos/                         # Todos (encrypted)
```

### Encrypted File Patterns

Defined in `.gitattributes`:

```gitattributes
secrets/** filter=age diff=age
todos/** filter=age diff=age
Brewfile filter=age diff=age
CLAUDE.md filter=age diff=age
**/**.secret.* filter=age diff=age
```

## CI/CD Pipeline

### Test Matrix

Tests run on every push:

- **Platforms**: Ubuntu 24.04, macOS 15
- **Tests**: Syntax, linting, validation
- **Tools**: Installed via Homebrew

### Workflow Steps

```yaml
1. Checkout repository (with submodules)
2. Install Homebrew (Linux only)
3. Install testing tools (fish, shellcheck, markdownlint)
4. Test Fish syntax and config loading
5. Lint shell scripts (shellcheck)
6. Lint Markdown files (markdownlint)
7. Validate Taskfile against schema
```

### Security

- **Pinned actions**: SHA-pinned for reproducibility
- **Minimal permissions**: `contents: read` only
- **No secrets**: Public repository, no sensitive data
- **Encrypted files**: Age-encrypted, safe in repository

## Extension Points

### Adding New Dotfiles

1. Add to chezmoi: `chezmoi add ~/.config/new-tool`
2. If sensitive: `chezmoi add --encrypt ~/.config/secret`
3. Test: `task test && task lint`
4. Commit and push

### Adding New Tests

1. Add task to `Taskfile.yaml`:

   ```yaml
   test:new:
     desc: Test new functionality
     sources:
       - path/to/files/**
     cmds:
       - command-to-test
   ```

2. Add to `test` dependencies
3. Document in `TESTING.md`

### Adding New Tools

1. Add to mise config:

   ```bash
   mise use new-tool@version
   ```

2. Update documentation
3. Commit `.config/mise/config.toml`

## Performance Considerations

### Taskfile Caching

Tasks only re-run when sources change:

- Checks file modification times
- Compares against previous run
- Skips unchanged tasks

### Chezmoi Apply

Only modified files are updated:

- Compares source with target
- Skips unchanged files
- Fast for incremental changes

### Git Filter Performance

Encryption/decryption is fast:

- age is designed for speed
- Only processes changed files
- Minimal overhead on git operations

## Security Considerations

### Age Key Protection

- **Never commit**: `.gitignore` prevents accidental commit
- **Restricted permissions**: `chmod 600` required
- **Backup**: Stored in 1Password
- **Rotation**: Generate new key, re-encrypt all files

### Git Filter Security

- **Clean filter**: Always encrypts before commit
- **Smudge filter**: Falls back to encrypted if decrypt fails
- **Required flag**: Git enforces filter usage

### Secret Handling

- **Encrypted at rest**: All secrets age-encrypted
- **Encrypted in transit**: Git transfers encrypted data
- **Plain in working dir**: Only decrypted locally
- **Ignored patterns**: `.chezmoiignore` prevents leak

## Future Improvements

Potential enhancements:

1. **Multiple age recipients**: Support key rotation
2. **Pre-commit hooks**: Enforce testing before commit
3. **ShellSpec tests**: Add behavioral testing for Fish functions
4. **Docker development**: Containerized testing environment
5. **Automated backups**: Schedule age key backups

## References

- [Chezmoi Documentation](https://chezmoi.io/)
- [Age Specification](https://age-encryption.org/)
- [Taskfile Guide](https://taskfile.dev/)
- [Mise Documentation](https://mise.jdx.dev/)
