# Contributing to .dotfiles

Thank you for your interest in contributing! This document provides guidelines for contributing to this dotfiles repository.

## Getting Started

### Prerequisites

- macOS (tested on macOS 15)
- [Homebrew](https://brew.sh)
- Git with GPG signing configured
- [mise](https://mise.jdx.dev/) for tool management

### Setup Development Environment

1. Fork and clone the repository:

   ```bash
   git clone https://github.com/YOUR_USERNAME/.dotfiles ~/Projects/github.com/YOUR_USERNAME/.dotfiles
   cd ~/Projects/github.com/YOUR_USERNAME/.dotfiles
   ```

2. Add upstream remote:

   ```bash
   git remote add upstream https://github.com/bartsmykla/.dotfiles
   ```

3. Install dependencies:

   ```bash
   mise install
   brew bundle install --file=Brewfile
   ```

## Development Workflow

### Making Changes

1. Create a new branch from master:

   ```bash
   git checkout master
   git fetch upstream
   git rebase upstream/master
   git checkout -b your-feature-branch
   ```

2. Make your changes in the appropriate location:
   - Dotfiles: `chezmoi/` source directory
   - Documentation: `docs/`, root `.md` files
   - Tasks: `Taskfile.yaml`
   - CI: `.github/workflows/`

3. Test your changes:

   ```bash
   task test          # Run all tests
   task lint          # Run all linters
   ```

### Commit Guidelines

Follow [Conventional Commits](https://conventionalcommits.org/) format:

```text
type(scope): description

Body (optional, max 72 chars per line)

Footer (optional)
```

#### Commit Types

Use specific types for infrastructure changes:

| Type | Use Case | Example |
|------|----------|---------|
| `feat` | New user-facing feature | `feat(fish): add git helper function` |
| `fix` | Bug fix | `fix(chezmoi): correct age encryption path` |
| `docs` | Documentation only | `docs(readme): add installation steps` |
| `ci` | CI/CD changes | `ci(workflow): add macos-14 to test matrix` |
| `test` | Test changes | `test(fish): add syntax validation` |
| `chore` | Maintenance tasks | `chore(deps): update shellcheck to 0.10.0` |
| `refactor` | Code refactoring | `refactor(fish): simplify git push functions` |
| `build` | Build system changes | `build(taskfile): add new lint task` |

**Important**: Use `ci(...)` not `fix(ci)`, `test(...)` not `feat(test)`, etc.

#### Commit Signing

All commits must be signed with `-sS`:

```bash
git commit -sS -m "type(scope): description"
```

#### Commit Message Format

- **Title**: Max 50 characters, use backticks for code/commands/files
- **Body**: Max 72 characters per line, explain "why" not "what"
- **No AI footer**: Remove Claude Code attribution

**Good examples**:

```bash
git commit -sS -m "feat(fish): add kubernetes context switcher

Add \`kctx\` function for quick context switching with fzf integration.
Improves workflow when working with multiple clusters."
```

```bash
git commit -sS -m "docs(age): document key rotation process"
```

**Bad examples**:

```bash
# Too vague
git commit -m "fix stuff"

# Wrong type (should be ci, not fix)
git commit -m "fix(ci): update workflow"

# Not signed
git commit -m "feat(fish): add function"
```

### Testing Requirements

All changes must pass testing:

```bash
task test && task lint
```

#### Test Coverage

- **Shell scripts**: Must pass `shellcheck`
- **Fish functions**: Must have valid syntax (`fish -n`)
- **Markdown**: Must pass `markdownlint`
- **Taskfile**: Must validate against schema

See [TESTING.md](TESTING.md) for comprehensive testing documentation.

### Pull Request Process

1. Ensure all tests pass locally
2. Push your branch to your fork:

   ```bash
   git push origin your-feature-branch
   ```

3. Create a pull request:

   ```bash
   gh pr create --base master --head YOUR_USERNAME:your-feature-branch
   ```

4. Fill in the PR template:
   - Clear description of changes
   - Link related issues
   - Include test results if applicable

5. Respond to review feedback and update PR as needed

## Code Style Guidelines

### Shell Scripts

- Use long flags for readability: `--force` not `-f`
- Must pass `shellcheck` with no warnings
- Add descriptions to Fish functions: `--description "..."` or `-d "..."`
- Use proper error handling

### Documentation

- Use Markdown for all documentation
- Add blank line after all headers
- Use backticks for code, commands, file paths
- Keep lines readable (no hard limit, but be reasonable)
- Capitalize "Markdown" not "markdown"

### Taskfile

- Group related tasks with comments
- Use descriptive task names: `test:fish` not `tf`
- Include `desc:` for all tasks
- Use `sources:` and `generates:` for caching
- Validate against schema: `task lint:taskfile`

## Project Structure

```text
.dotfiles/
├── chezmoi/                    # Chezmoi source directory
│   ├── .chezmoi.toml.tmpl     # Chezmoi config template
│   ├── .chezmoiignore         # Ignore patterns
│   └── private_dot_config/    # Config files (~/.config/)
│       └── fish/              # Fish shell config
│           ├── config.fish
│           └── functions/     # Custom functions
├── docs/                       # Documentation
│   ├── age-encryption.md      # Age encryption guide
│   └── DEBUGGING.md           # Debugging guide
├── .github/
│   └── workflows/
│       └── test.yaml          # CI/CD pipeline
├── Taskfile.yaml              # Task automation
├── Brewfile                   # Homebrew packages (encrypted)
├── README.md                  # Project overview
├── TESTING.md                 # Testing documentation
├── ARCHITECTURE.md            # Architecture docs
└── CONTRIBUTING.md            # This file
```

## Encryption

### Working with Encrypted Files

Files encrypted with age should not expose sensitive data in commits.

**Adding encrypted files**:

```bash
chezmoi add --encrypt ~/.config/secret-file
```

**Editing encrypted files**:

```bash
chezmoi edit ~/.config/secret-file
```

**Never commit**:

- Plain-text secrets
- Age private keys
- Personal API tokens

See [docs/age-encryption.md](docs/age-encryption.md) for details.

## Getting Help

- Check [TESTING.md](TESTING.md) for testing issues
- Check [docs/DEBUGGING.md](docs/DEBUGGING.md) for debugging
- Check [ARCHITECTURE.md](ARCHITECTURE.md) for design decisions
- Open an issue for bugs or feature requests

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
