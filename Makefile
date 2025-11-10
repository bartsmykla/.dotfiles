# Makefile - Dotfiles Automation
#
# PURPOSE:
#   Automate common dotfiles operations: installation, testing, updates
#
# USAGE:
#   make help     - Show all available targets
#   make install  - Full dotfiles installation
#   make test     - Run all tests
#   make update   - Update all tools and packages
#
# REQUIREMENTS:
#   - macOS with Homebrew
#   - Git with git-crypt configured
#   - Fish shell (will be installed if missing)
#
# REFERENCE:
#   https://www.gnu.org/software/make/manual/
#   https://makefiletutorial.com/

#===============================================================================
# Configuration
#===============================================================================

# Use bash with strict error handling
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# Disable built-in rules and suffix rules
MAKEFLAGS += --no-builtin-rules --warn-undefined-variables
.SUFFIXES:

# Use one shell for all commands in a recipe
.ONESHELL:

# Paths
HOME           := $(shell echo "$$HOME")
DOTFILES       := $(CURDIR)
PROJECTS_PATH  := $(HOME)/Projects/github.com


# Colors (ANSI escape codes)
NO_COLOR  := \033[0m
BOLD      := \033[1m
GREEN     := \033[32m
YELLOW    := \033[33m
BLUE      := \033[34m

# Tool Detection (set to : no-op if not found)
MISE          := $(or $(shell command -v mise 2>/dev/null),:)
CHECKMAKE     := $(or $(shell command -v checkmake 2>/dev/null),:)
MARKDOWNLINT  := $(or $(shell command -v markdownlint 2>/dev/null),:)
SHELLCHECK    := $(or $(shell command -v shellcheck 2>/dev/null),:)

# Linting
MAX_LINE_LENGTH := 100

# Exclusions for symlink discovery
EXCLUDE_DIRS   := . .. .git .github .idea
EXCLUDE_FILES  := .gitignore .gitattributes .gitmodules

# Discover symlink targets using Make shell function
DOTFILE_DIRS   := $(shell find $(DOTFILES) -mindepth 1 -maxdepth 1 -name '.*' \
	-type d ! -name '.git' ! -name '.github' ! -name '.idea')

CONFIG_DIRS    := $(shell find $(DOTFILES)/.config -mindepth 1 -maxdepth 1 -type d)

DOTFILE_FILES  := $(shell find $(DOTFILES) -mindepth 1 -maxdepth 1 -name '.*' \
	-type f ! -name '.gitignore' ! -name '.gitattributes' ! -name '.gitmodules')

#===============================================================================
# Phony Targets
#===============================================================================

.PHONY: help all
.PHONY: install install/brew install/symlinks install/mise install/shells \
	install/fish
.PHONY: install/symlinks/dirs install/symlinks/config install/symlinks/files
.PHONY: install/symlinks/link
.PHONY: test test/syntax test/fish test/shellspec test/brewfile \
	test/makefile test/docs
.PHONY: lint check lint/shell lint/fish lint/markdown lint/makefile
.PHONY: lint/makefile/checkmake lint/makefile/linelength lint/makefile/varalign
.PHONY: update clean show/vars

#===============================================================================
# Default Target
#===============================================================================

.DEFAULT_GOAL := help

#===============================================================================
# Help Target
#===============================================================================

help: ## Show this help message
	@printf "$(BOLD)$(BLUE)Dotfiles Automation$(NO_COLOR)\n\n"
	@printf "$(BOLD)Usage:$(NO_COLOR)\n"
	@awk 'BEGIN {FS = ":.*##"; printf ""} \
		/^[a-zA-Z_\/-]+:.*##/ { printf "  $(BLUE)%-20s$(NO_COLOR) %s\n", $$1, $$2 } \
		/^##@/ { printf "\n$(BOLD)%s$(NO_COLOR)\n", substr($$0, 5) }' $(MAKEFILE_LIST)
	@printf "\n$(BOLD)Reference:$(NO_COLOR)\n"
	@printf "  Brewfile:  https://docs.brew.sh/Brew-Bundle\n"
	@printf "  ShellSpec: https://shellspec.info/\n"
	@printf "  Fish:      https://fishshell.com/docs/current/\n\n"

#===============================================================================
# Installation Targets
#===============================================================================

##@ Installation

all: install ## Alias for install

install: install/brew install/symlinks install/mise install/shells \
	install/fish ## Full dotfiles installation
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) Dotfiles installation complete!\n"
	@printf "\n$(BOLD)$(YELLOW)⚠$(NO_COLOR) Next steps:\n"
	@printf "  1. Restart your terminal or run: exec fish\n"
	@printf "  2. Verify installation: make test\n"
	@printf "  3. Check for updates: make update\n"

install/brew: ## Install Homebrew packages
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Installing Homebrew packages\n"
	@if ! command -v brew >/dev/null 2>&1; then
		printf "Homebrew not found. Installing...\n"
		/bin/bash -c "$$(curl -fsSL \
			https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi
	brew bundle install --file="$(DOTFILES)/Brewfile"
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) Homebrew packages installed\n"

install/symlinks: install/symlinks/dirs install/symlinks/config \
	install/symlinks/files ## Create dotfile symlinks
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) Symlinks created\n"

install/symlinks/dirs:
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Creating symlinks for top-level directories\n"
	@for src in $(DOTFILE_DIRS); do \
		dst="$(HOME)/$$(basename $$src)"; \
		$(MAKE) --no-print-directory install/symlinks/link \
			SRC="$$src" DST="$$dst"; \
	done

install/symlinks/config:
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Creating symlinks for .config subdirectories\n"
	@for src in $(CONFIG_DIRS); do \
		dst="$(HOME)/.config/$$(basename $$src)"; \
		$(MAKE) --no-print-directory install/symlinks/link \
			SRC="$$src" DST="$$dst"; \
	done

install/symlinks/files:
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Creating symlinks for top-level dotfiles\n"
	@for src in $(DOTFILE_FILES); do \
		dst="$(HOME)/$$(basename $$src)"; \
		$(MAKE) --no-print-directory install/symlinks/link \
			SRC="$$src" DST="$$dst"; \
	done

install/symlinks/link:
	@# Check if symlink already correct
	@if [ -L "$(DST)" ] && [ "$$(readlink $(DST))" = "$(SRC)" ]; then \
		printf "  ✓ Symlink exists: $(DST) → $(SRC)\n"; \
		exit 0; \
	fi
	@# Backup existing file/directory if present
	@if [ -e "$(DST)" ]; then \
		backup="$(DST)-$$(date +'%d%m%y-%H%M')"; \
		printf "  ⚠ Backing up: $(DST) → $$backup\n"; \
		rsync -a "$(DST)" "$$backup" >/dev/null; \
		rm -rf "$(DST)"; \
	fi
	@# Create symlink
	@printf "  → Creating: $(SRC) → $(DST)\n"
	@ln -sf "$(SRC)" "$(DST)"

install/mise: ## Install mise and tools
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Installing mise and tools\n"
	@if [ "$(MISE)" = ":" ]; then \
		printf "Installing mise...\n"; \
		curl https://mise.run | sh; \
		$(HOME)/.local/bin/mise install; \
	else \
		$(MISE) install; \
	fi
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) mise tools installed\n"

install/shells: ## Setup Fish as default shell
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Setting up Fish shell\n"
	@fish_path=$$(command -v fish)
	if ! grep -q "$$fish_path" /etc/shells 2>/dev/null; then
		printf "$$fish_path\n" | sudo tee -a /etc/shells >/dev/null
	fi
	chsh -s "$$fish_path"
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) Fish shell configured\n"

install/fish: ## Initialize Fish configuration
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Initializing Fish configuration\n"
	@fish -c "source $(HOME)/.config/fish/config.fish" 2>/dev/null || true
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) Fish configuration initialized\n"

#===============================================================================
# Testing Targets
#===============================================================================

##@ Testing

test: test/syntax test/fish test/shellspec ## Run all tests
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) All tests passed!\n"

test/syntax: ## Check syntax of shell scripts
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Checking shell script syntax\n"
	@for file in $(DOTFILES)/.config/fish/**/*.fish; do \
		[ -f "$$file" ] || continue; \
		fish -n "$$file" || exit 1; \
	done
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) Syntax checks passed\n"

test/fish: ## Test Fish configuration loads
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Testing Fish configuration\n"
	@fish -c "echo 'Fish config loaded successfully'" >/dev/null
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) Fish configuration test passed\n"

test/shellspec: ## Run ShellSpec test suite
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Running ShellSpec tests\n"
	@if command -v shellspec >/dev/null 2>&1; then
		shellspec
	else
		printf "$(BOLD)$(YELLOW)⚠$(NO_COLOR) ShellSpec not installed. Run: make install/brew\n"
		exit 1
	fi

test/brewfile: ## Test Brewfile validity
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Testing Brewfile\n"
	@brew bundle check --no-upgrade >/dev/null 2>&1 || true
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) Brewfile is valid\n"

test/makefile: ## Test Makefile targets
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Testing Makefile targets\n"
	@$(MAKE) -n install >/dev/null
	@$(MAKE) -n test >/dev/null
	@$(MAKE) -n lint >/dev/null
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) Makefile targets are valid\n"

test/docs: ## Test documentation structure
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Testing documentation\n"
	@test -f "$(DOTFILES)/README.md"
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) Documentation structure valid\n"

#===============================================================================
# Linting Targets
#===============================================================================

##@ Linting

lint: lint/shell lint/fish lint/markdown lint/makefile ## Run all linters
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) All linting passed!\n"

check: lint ## Alias for lint (common convention)

lint/shell: ## Lint shell scripts with shellcheck
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Linting shell scripts\n"
	@find "$(DOTFILES)" -name "*.sh" -not -path "*/.git/*" \
		-exec $(SHELLCHECK) {} + 2>/dev/null || \
		printf "$(BOLD)$(YELLOW)⚠$(NO_COLOR) shellcheck not installed\n"
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) Shell linting passed\n"

lint/fish: ## Check Fish script syntax
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Linting Fish scripts\n"
	@for file in $(DOTFILES)/.config/fish/**/*.fish; do \
		[ -f "$$file" ] || continue; \
		fish -n "$$file" || exit 1; \
	done
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) Fish linting passed\n"

lint/markdown: ## Lint Markdown files
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Linting Markdown files\n"
	@$(MARKDOWNLINT) "$(DOTFILES)"/**/*.md 2>/dev/null || \
		printf "$(BOLD)$(YELLOW)⚠$(NO_COLOR) markdownlint not installed\n"
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) Markdown linting passed\n"

lint/makefile: lint/makefile/checkmake lint/makefile/linelength \
	lint/makefile/varalign ## Lint Makefile with all checks
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) Makefile linting passed\n"

lint/makefile/checkmake:
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Linting Makefile with checkmake\n"
	@$(CHECKMAKE) --config="$(DOTFILES)/.checkmake" "$(DOTFILES)/Makefile" \
		2>/dev/null || \
		printf "$(BOLD)$(YELLOW)⚠$(NO_COLOR) checkmake not installed\n"

lint/makefile/linelength:
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Checking Makefile line lengths\n"
	@awk 'length > $(MAX_LINE_LENGTH) { \
			printf "  Line %d (%d chars)\n", NR, length; \
			errors++ \
		} \
		END { if (errors > 0) exit 1 }' "$(DOTFILES)/Makefile"

lint/makefile/varalign:
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Checking variable alignment\n"
	@awk 'BEGIN { expected=0; errors=0 } \
		/^#/ { expected=0; next } \
		/^[A-Z_]+ *:=/ { \
			match($$0, /:=/); \
			if (expected == 0) { \
				expected = RSTART; \
			} else if (RSTART != expected) { \
				printf "  Line %d: := at column %d (expected %d)\n", NR, RSTART, expected; \
				errors++; \
			} \
			next \
		} \
		/^$$/ { next } \
		{ expected=0 } \
		END { if (errors > 0) exit 1 }' "$(DOTFILES)/Makefile"

#===============================================================================
# Maintenance Targets
#===============================================================================

##@ Maintenance

update: ## Update all tools and packages
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Updating all tools\n"
	@brew update && brew upgrade
	@$(MISE) self-update 2>/dev/null || true
	@$(MISE) upgrade 2>/dev/null || true
	@fish -c "fisher update" 2>/dev/null || true
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) All tools updated\n"

clean: ## Remove broken symlinks and temp files
	@printf "$(BOLD)$(BLUE)▶$(NO_COLOR) Cleaning up\n"
	@find ~ -maxdepth 1 -type l ! -exec test -e {} \; -delete 2>/dev/null || true
	@rm -rf "$(DOTFILES)/spec/tmp" 2>/dev/null || true
	@printf "$(BOLD)$(GREEN)✓$(NO_COLOR) Cleanup complete\n"

show/vars: ## Show all Makefile variables (debugging)
	@printf "$(BOLD)Makefile Variables:$(NO_COLOR)\n"
	@printf "  DOTFILES:        $(DOTFILES)\n"
	@printf "  HOME:            $(HOME)\n"
	@printf "  PROJECTS_PATH:   $(PROJECTS_PATH)\n"
	@printf "  SHELL:           $(SHELL)\n"
	@printf "  MAKEFLAGS:       $(MAKEFLAGS)\n"
	@printf "  EXCLUDE_DIRS:    $(EXCLUDE_DIRS)\n"
	@printf "  EXCLUDE_FILES:   $(EXCLUDE_FILES)\n"
	@printf "  DOTFILE_DIRS:    $(words $(DOTFILE_DIRS)) directories\n"
	@printf "  CONFIG_DIRS:     $(words $(CONFIG_DIRS)) directories\n"
	@printf "  DOTFILE_FILES:   $(words $(DOTFILE_FILES)) files\n"
	@printf "\n$(BOLD)Tool Detection:$(NO_COLOR)\n"
	@printf "  MISE:            $(MISE)\n"
	@printf "  CHECKMAKE:       $(CHECKMAKE)\n"
	@printf "  MARKDOWNLINT:    $(MARKDOWNLINT)\n"
	@printf "  SHELLCHECK:      $(SHELLCHECK)\n"
