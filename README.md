# .dotfiles

Personal macOS dotfiles managed with [chezmoi](https://chezmoi.io), encrypted with [age](https://age-encryption.org/), and automated with [Taskfile](https://taskfile.dev).

## Quick Start

### Prerequisites

- macOS (tested on macOS 15)
- [Homebrew](https://brew.sh)
- Git

### Installation

1. Install mise:

   ```bash
   curl https://mise.run | sh
   ```

2. Clone repository:

   ```bash
   git clone https://github.com/bartsmykla/.dotfiles ~/Projects/github.com/bartsmykla/.dotfiles
   cd ~/Projects/github.com/bartsmykla/.dotfiles
   ```

3. Install dependencies:

   ```bash
   mise install
   brew bundle install --file=Brewfile
   ```

4. Set up age encryption key:

   ```bash
   mkdir -p ~/.config/chezmoi
   # Copy your age key to ~/.config/chezmoi/key.txt
   chmod 600 ~/.config/chezmoi/key.txt
   ```

5. Initialize and apply dotfiles:

   ```bash
   chezmoi init
   chezmoi diff    # Review changes
   chezmoi apply   # Apply dotfiles
   ```

## Features

- **Dotfiles Management**: Declarative configuration with [chezmoi](https://chezmoi.io)
- **Encryption**: Age encryption for secrets (`~/.claude`, `~/.config/k9s/config.yaml`, etc.)
- **Task Automation**: Taskfile for linting, testing, and common operations
- **Version Management**: mise for managing tool versions (shellcheck, markdownlint, task, etc.)
- **CI/CD**: Automated testing on Ubuntu 24.04 and macOS 15
- **Fish Shell**: Custom functions, completions, and integrations (fzf, atuin, starship)

## Usage

### Taskfile Commands

```bash
task test          # Run all tests
task lint          # Run all linters
task check         # Alias for lint

task test:fish     # Test Fish config
task lint:shell    # Shellcheck validation
task lint:markdown # Markdown linting

task --list        # Show all tasks
```

See [TESTING.md](TESTING.md) for comprehensive testing documentation.

### Chezmoi Workflow

#### Adding Files

```bash
chezmoi add --encrypt ~/.config/secret-file    # Add encrypted
chezmoi add ~/.config/normal-file              # Add plain
```

#### Editing Files

```bash
chezmoi edit ~/.config/secret-file             # Edit encrypted file
chezmoi edit ~/.config/fish/config.fish        # Edit plain file
```

#### Applying Changes

```bash
chezmoi diff                                   # Preview changes
chezmoi apply                                  # Apply to home directory
chezmoi apply --verbose                        # Verbose output
```

#### Syncing Changes

After modifying files in the chezmoi source directory:

```bash
cd ~/Projects/github.com/bartsmykla/.dotfiles
git add -A
git commit -sS -m "type(scope): description"
git push upstream master
```

See [chezmoi documentation](https://chezmoi.io/user-guide/command-overview/) for more commands.

## Configuration

### Encrypted Files

Files encrypted with age:

| Location                                   | Description                      |
|--------------------------------------------|----------------------------------|
| `~/.claude/**`                             | Claude Code configuration        |
| `~/.config/fish/conf.d/abbreviations.fish` | Fish abbreviations               |
| `~/.config/k9s/config.yaml`                | K9s configuration                |
| `Brewfile`                                 | Homebrew packages (repository)   |
| `CLAUDE.md`                                | Claude instructions (repository) |
| `secrets/`, `todos/`                       | Secrets and todos (repository)   |

### Age Encryption Key

Key location: `~/.config/chezmoi/key.txt`

**Important**: Keep this key secure and backed up to a password manager or encrypted storage.

See [docs/age-encryption.md](docs/age-encryption.md) for detailed encryption documentation.

### Environment Variables

Key variables defined in `.config/fish/config.fish`:

| Variable           | Value                         | Description            |
|--------------------|-------------------------------|------------------------|
| `PROJECTS_PATH`    | `$HOME/Projects/github.com`   | Base path for projects |
| `MY_PROJECTS_PATH` | `$PROJECTS_PATH/bartsmykla`   | Personal projects      |
| `DOTFILES_PATH`    | `$MY_PROJECTS_PATH/.dotfiles` | Dotfiles repository    |
| `SECRETS_PATH`     | `$DOTFILES_PATH/secrets`      | Encrypted secrets      |

## Fish Shell

### Custom Functions

| Function                                   | Description                                      |
|--------------------------------------------|--------------------------------------------------|
| `link_dotfile`                             | Symlink dotfiles with automatic backup           |
| `git_clone_to_projects`                    | Clone repos to `$PROJECTS_PATH/{org}/{repo}`     |
| `git-checkout-default-fetch-fast-forward`  | Checkout, fetch, and fast-forward default branch |
| `git-push-upstream-first-force-with-lease` | Push to upstream with `--force-with-lease`       |
| `klg`                                      | Kubernetes pod logs                              |
| `kls`                                      | List Kubernetes resources                        |
| `mkd`                                      | Create directory and cd into it                  |

### Integrations

- **fzf**: Fuzzy finder for directories, git log/status, processes, variables
- **Atuin**: Shell history sync and search
- **direnv**: Auto-load environment from `.envrc`
- **starship**: Cross-shell prompt
- **jump**: Quick directory navigation
- **1Password**: SSH agent integration

## macOS Setup

### Disable Conflicting Keyboard Shortcuts

<details>
<summary>Ctrl + Space and Cmd + Space conflicts</summary>

1. Open System Settings > Keyboard:

   ```bash
   open -b com.apple.systempreferences /System/Library/PreferencePanes/Keyboard.prefPane
   ```

2. **Ctrl + Space** (for Fish autosuggestion):

   Navigate to **Input Sources** tab and unselect:
   - Select the previous input source (`⌃Space`)
   - Select next source in input menu (`⌃⌥Space`)

3. **Cmd + Space** (for Alfred):

   Navigate to **Spotlight** tab and unselect:
   - Show Spotlight search (`⌘Space`)
   - Show Finder search window (`⌥⌘Space`)

</details>

### Show Only Active Apps in Dock

```bash
defaults write com.apple.dock static-only -bool true
killall Dock
```

## Development

### Running Tests

Before committing:

```bash
task test && task lint
```

### Tool Management

Update tools managed by mise:

```bash
mise ls-remote shellcheck     # List available versions
mise use shellcheck@0.10.0    # Pin specific version
mise install                  # Install tools
```

Commit updated `.config/mise/config.toml` after changes.

### File Structure

```text
.dotfiles/
├── chezmoi/              # Chezmoi source directory
│   ├── .chezmoi.toml.tmpl
│   ├── .chezmoiignore
│   └── private_dot_config/
├── docs/                 # Documentation
├── .github/workflows/    # CI/CD
├── Taskfile.yaml         # Task automation
├── Brewfile              # Homebrew packages (encrypted)
└── CLAUDE.md             # Claude Code instructions (encrypted)
```

## Troubleshooting

### Chezmoi Issues

**Files not syncing**:

```bash
chezmoi verify
```

**Preview what chezmoi would do**:

```bash
chezmoi apply --dry-run --verbose
```

### Encryption Issues

**Decryption failed**:

```bash
ls -la ~/.config/chezmoi/key.txt    # Check key exists
chmod 600 ~/.config/chezmoi/key.txt # Fix permissions
age --version                        # Verify age installed
```

### Testing Issues

See [TESTING.md](TESTING.md#troubleshooting) for testing troubleshooting.

## Documentation

- [TESTING.md](TESTING.md) - Testing approach, commands, CI integration
- [docs/age-encryption.md](docs/age-encryption.md) - Age encryption guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture and design
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contributing guidelines
- [docs/DEBUGGING.md](docs/DEBUGGING.md) - Debugging guide

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.
