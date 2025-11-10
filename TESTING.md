# Testing Documentation

This document explains the testing approach, philosophy, and how to run tests locally and in CI.

## Overview

The dotfiles repository uses automated testing to ensure:

- Shell scripts have correct syntax
- Configuration files are valid
- Linters pass quality checks
- Changes don't break existing functionality

All tests are automated via Taskfile and run in CI on every push.

## Testing Philosophy

### Goals

1. **Catch Errors Early**: Syntax errors and common mistakes before they cause problems
2. **Maintain Quality**: Consistent code style and best practices
3. **Fast Feedback**: Tests run quickly for rapid iteration
4. **Clear Failures**: Test failures clearly indicate what's wrong

### What We Test

- **Syntax**: Fish scripts, Bash scripts, Markdown files
- **Validity**: Brewfile dependencies, Taskfile schema
- **Quality**: Shellcheck linting, Markdown linting
- **Functionality**: Fish configuration loads without errors

### What We Don't Test

- **User Workflows**: Manual chezmoi workflows (tested in Phase 9)
- **Integration**: Cross-tool interactions (validated end-to-end)
- **Machine-Specific**: Hardware or OS-specific features

## Running Tests Locally

### Quick Start

Run all tests and linters:

```bash
task test
task lint
```

Or use the common alias:

```bash
task check  # Same as 'task lint'
```

### Individual Test Suites

#### Fish Scripts

```bash
task test:fish        # Test Fish config loads
task lint:fish        # Check Fish syntax
```

#### Shell Scripts

```bash
task lint:shell       # Shellcheck all scripts
task test:syntax      # Check syntax of all scripts
```

#### Markdown Files

```bash
task lint:markdown    # Lint Markdown files
```

#### Brewfile

```bash
task test:brewfile    # Validate Brewfile
```

#### Taskfile

```bash
task lint:taskfile    # Validate Taskfile.yml schema
```

#### ShellSpec (if tests exist)

```bash
task test:shellspec   # Run ShellSpec test suite
```

### Test Output

Tests provide clear output:

- **✅ Success**: Green checkmark and brief success message
- **❌ Failure**: Red X with detailed error information
- **→ Running**: Progress indicator for long-running tests

Example output:

```text
task: [test:fish] Testing Fish configuration loads...
✅ Fish config loaded successfully

task: [lint:shell] Running shellcheck on shell scripts...
✅ All shell scripts passed shellcheck

task: [test] All tests passed!
```

## Continuous Integration

### GitHub Actions Workflow

Tests run automatically on:

- Every push to any branch
- Every pull request
- Manual workflow dispatch

Location: `.github/workflows/test.yml`

### CI Test Matrix

Tests run on multiple platforms:

- **Ubuntu 24.04**: Linux compatibility
- **macOS 15**: macOS compatibility

### CI Workflow Steps

1. **Checkout code**: Clone repository
2. **Setup mise**: Install mise version manager
3. **Install tools**: Install mise-managed tools (shellcheck, markdownlint, task)
4. **Run tests**: Execute `task test`
5. **Run linters**: Execute `task lint`

### Viewing CI Results

Check CI status:

1. Go to repository on GitHub
2. Click "Actions" tab
3. View workflow runs and results

✅ = all tests passed
❌ = tests failed (click for details)

## Adding New Tests

### For Shell Scripts

1. Add script to repository
2. Ensure it has `.sh`, `.bash`, or `.fish` extension
3. Tests will automatically include it:
   - Syntax checking via file extension
   - Shellcheck linting (for Bash scripts)
   - Fish syntax checking (for Fish scripts)

### For ShellSpec Tests

Create test files in `spec/` directory:

```bash
# spec/my_function_spec.sh
Describe 'my_function'
  It 'returns expected output'
    When call my_function arg1 arg2
    The output should equal "expected output"
    The status should be success
  End
End
```

Run with:

```bash
task test:shellspec
```

### For New File Types

To add linting for a new file type:

1. Add tool to `mise` configuration
2. Create new lint task in `Taskfile.yml`:

   ```yaml
   lint:newtype:
     desc: Lint newtype files
     cmd: newtypelinter **/*.newtype
   ```

3. Add to main `lint` task dependencies

## Test Configuration

### Shellcheck

Configuration: `.shellcheckrc` (if exists)

Shellcheck checks for:

- Common shell scripting errors
- Portability issues
- Deprecated syntax
- Security issues

### Markdownlint

Configuration: `.markdownlint.json`

Current rules:

- MD022: Blank lines around headings (enabled)
- Standard Markdown best practices

### Fish Syntax

Tests that Fish configuration:

- Loads without errors
- Has valid syntax
- Sources all functions correctly

## Troubleshooting

### Test Failures

#### Shellcheck Errors

```text
In script.sh line 10:
command $variable
^-- SC2086: Double quote to prevent globbing
```

**Fix**: Add quotes around variables:

```bash
command "$variable"
```

#### Markdown Lint Errors

```text
file.md:1 MD022/blanks-around-headings
Headings should be surrounded by blank lines
```

**Fix**: Add blank lines before and after headings:

```markdown
# Heading

Content here.
```

#### Fish Syntax Errors

```text
fish: Unknown command: invalid_command
```

**Fix**: Check Fish function syntax and ensure all functions are defined.

### Common Issues

#### Tests Pass Locally But Fail in CI

**Cause**: Different tool versions or environment

**Solution**:

1. Check mise tool versions match CI
2. Run `mise install` to sync versions
3. Commit version changes to `mise` config

#### Shellcheck Not Found

**Cause**: Tool not installed via mise

**Solution**:

```bash
mise install shellcheck
```

#### Task Command Not Found

**Cause**: Task not installed or not in PATH

**Solution**:

```bash
mise install task
mise reshim
```

## Best Practices

### Before Committing

Always run tests before committing:

```bash
task test && task lint
```

Or use the pre-commit hook (if configured).

### Writing Testable Code

1. **Keep functions small**: Easier to test
2. **Use clear names**: Tests document behavior
3. **Handle errors**: Test error paths
4. **Avoid side effects**: Pure functions are testable

### Writing Good Tests

1. **Test one thing**: Each test validates one behavior
2. **Use descriptive names**: Test name explains what's being tested
3. **Arrange-Act-Assert**: Setup, execute, verify pattern
4. **Test edge cases**: Empty input, nulls, extremes

## Performance

### Test Execution Times

Typical test times on modern hardware:

- Syntax checks: <1 second
- Shellcheck: 1-2 seconds
- Markdown lint: <1 second
- ShellSpec: 2-5 seconds (if tests exist)
- **Total**: ~5-10 seconds

### Optimizing Tests

Tests are already optimized for speed:

- Parallel execution where possible
- Smart caching via Taskfile `sources` and `generates`
- Minimal dependencies (only mise and its tools)

## Maintenance

### Updating Test Tools

Keep linting tools up to date:

```bash
mise ls-remote shellcheck      # See available versions
mise use shellcheck@latest     # Update to latest
mise install                   # Install new version
```

Commit the updated `.config/mise/config.toml`.

### Adding New Platforms

To test on additional platforms:

1. Edit `.github/workflows/test.yml`
2. Add new OS to matrix:

   ```yaml
   matrix:
     os: [ubuntu-24.04, macos-15, macos-14]  # Add new OS here
   ```

3. Test workflow runs on new platform

## References

- [Taskfile Documentation](https://taskfile.dev/)
- [ShellCheck Wiki](https://www.shellcheck.net/wiki/)
- [Markdownlint Rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md)
- [ShellSpec Documentation](https://shellspec.info/)
- [Fish Shell Documentation](https://fishshell.com/docs/current/)

## Related Documentation

- [CONTRIBUTING.md](CONTRIBUTING.md) - How to contribute (includes testing requirements)
- [docs/DEBUGGING.md](docs/DEBUGGING.md) - Debugging failed tests
- [ARCHITECTURE.md](ARCHITECTURE.md) - Overall system design
- [README.md](README.md) - Project overview and setup
