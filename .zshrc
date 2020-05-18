export ZSH=/Users/afrael/.oh-my-zsh

COMPLETION_WAITING_DOTS="true"
ZSH_CUSTOM="${HOME}/Projects/github.com/bartsmykla/oh-my-zsh-custom"
ZSH_THEME="robbyrussell"

# Plugins: ~/.oh-my-zsh/plugins/*
# Custom plugins: ~/.oh-my-zsh/custom/plugins/
plugins=(
  git
  aws
  brew # adds several brew related aliases like `bubo`, `bubc` etc.
  colorize
  docker
  gcloud # completion
  golang
  helm # completion
  history # adds aliases 'h', 'hs', 'hsi'
  history-substring-search
  iterm2 # adds few direct iterm2 functions like `iterm2_tab_color r g b` etc.
  kubectl # Completion for cluster manager + some kubectl aliases like `k` etc.
  kops # completion
  osx
  rust # completion for rustc
  tmux # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/tmux
  zsh-autosuggestions
  zsh_reload
)

source $ZSH/oh-my-zsh.sh

# ---

# Load add-zsh-hook to be able to call some function when something happens
# More: http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#Manipulating-Hook-Functions
autoload -U add-zsh-hook

# Vars
    readonly PROJECTS_PATH="${HOME}/Projects/github.com"
    readonly DOTFILES_PATH="${PROJECTS_PATH}/bartsmykla/.dotfiles"
    readonly CUSTOM_SCRIPTS_PATH="${DOTFILES_PATH}/custom_scripts"
    readonly SECRETS_PATH="${DOTFILES_PATH}/secrets"
    readonly ZSHRC="${DOTFILES_PATH}/.zshrc"
    export NVM_DIR="${HOME}/.nvm"

# Completions not handled by oh-my-zsh plugins
    source <(stern --completion=zsh)

# Custom functions
    source_custom_scripts() {
        local custom_scripts=("${CUSTOM_SCRIPTS_PATH}"/**/*(.))

        if [[ "${#custom_scripts}" != 0 ]]; then
            echo "Found files in custom scripts path (${CUSTOM_SCRIPTS_PATH})."
            for file in ${custom_scripts[@]}; do
                echo "    Sourcing: $(basename ${file})"
                source ${file}
            done
        fi
    }

    load_kopsrc() {
        local file=".kops"

        if [ -f "${file}" ]; then
            echo "found ${file}"
            source "${file}"
        fi
    }

    get_secret() {
        if [[ $# != 1 ]]; then
            echo -n "get_secret(name): function expects one argument" >&2
            echo    " to be passed" >&2
            return 1
        fi

        local name="${1}"

        if ! [[ -s "${SECRETS_PATH}/${name}" ]]; then
            echo -n "Secret ${name} doesn't exist in SECRETS_PATH" >&2
            echo    " (${SECRETS_PATH}) or is empty" >&2
            return 1
        fi

        cat "${SECRETS_PATH}/${name}"
    }

# Key binds
    # Skip forward/back a word with opt-arrow
    bindkey '[C' forward-word
    bindkey '[D' backward-word

    # accepting autosuggestions by using ctrl + space keys
    bindkey '^ ' autosuggest-accept

    bindkey '^U' backward-kill-line

# Hooks
    add-zsh-hook chpwd load_kopsrc

# Other ZSH
    autoload -Uz copy-earlier-word
    zle -N copy-earlier-word

# PATH
    # Custom binaries with superuser privileges required
    export PATH="/usr/local/sbin:${PATH}"
    # Overwrite default MacOS's version of getopt with the proper one
    export PATH="/usr/local/opt/gnu-getopt/bin:${PATH}"

# Secrets
    # Homebrew
    export HOMEBREW_GITHUB_API_TOKEN="$(get_secret HOMEBREW_GITHUB_API_TOKEN)"
    # AWS terraform_learning account
    export AWS_ACCESS_KEY_ID="$(get_secret AWS_ACCESS_KEY_ID)"
    export AWS_SECRET_ACCESS_KEY="$(get_secret AWS_SECRET_ACCESS_KEY)"

# Aliases:
    alias zshrc="${EDITOR:=vim} ${ZSHRC:=~/.zshrc}"
    alias hi="/Volumes/fortress/.hi" 
    alias b="cd ${PROJECTS_PATH}/bartsmykla"
    alias p="cd ${PROJECTS_PATH}"
    alias rem="rm -i"

# History management
    # Avoid duplicates
    HISTCONTROL=ignoredups:erasedups  

    # When the shell exits, append to the history file instead of overwriting it
    shopt -s histappend

    # After each command, append to the history file and reread it
    PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; 
        history -c; history -r"

# NVM
    if [[ -s "${NVM_DIR}/nvm.sh" ]]; then
        source "${NVM_DIR}/nvm.sh"
    fi

# For Ruby (added when installed vim/macvim)
    if ruby --version >/dev/null 2>&1; then
        export PATH="/usr/local/opt/ruby/bin:$PATH"
        export LDFLAGS="-L/usr/local/opt/ruby/lib"
        export CPPFLAGS="-I/usr/local/opt/ruby/include"
        export PKG_CONFIG_PATH="/usr/local/opt/ruby/lib/pkgconfig"
    fi

# ohmyzsh plugin history-substring-search
    source /usr/local/share/zsh-history-substring-search/zsh-history-substring-search.zsh

source_custom_scripts
load_kopsrc

