# TODO: Check dependencies (awk, flock, grep)

# Vars
    export PROJECTS_ROOT_PATH="${HOME}/Projects"
    export PROJECTS_PATH="${PROJECTS_ROOT_PATH}/github.com"
    readonly DOTFILES_PATH="${PROJECTS_PATH}/bartsmykla/.dotfiles"
    readonly CUSTOM_SCRIPTS_PATH="${DOTFILES_PATH}/autoload_scripts"
    readonly SECRETS_PATH="${DOTFILES_PATH}/secrets"
    readonly ZSHRC="${DOTFILES_PATH}/.zshrc"
    export NVM_DIR="${HOME}/.nvm"
    export ZSH="${HOME}/.oh-my-zsh"
    export CPPFLAGS=""
    readonly VOLUME_NAME="fortress"
    readonly KEY_NAME="fortress1_rsa"
    export EDITOR="vim"
    export MYVIMRCD="${DOTFILES_PATH}/.vimrc.d"

# ZSH
    ZSH_CUSTOM="${DOTFILES_PATH}/oh-my-zsh-custom"
    ZSH_THEME="robbyrussell"

    # Load add-zsh-hook to be able to call some function when something happens
    # More: http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#Manipulating-Hook-Functions
    autoload -U add-zsh-hook

# OH MY ZSH
    COMPLETION_WAITING_DOTS="true"

    # Plugins: ~/.oh-my-zsh/plugins/*
    # Custom plugins: ${ZSH_CUSTOM}/plugins/
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
        zsh-abbr
        zsh-autosuggestions
        zsh_reload
    )

    source "${ZSH}/oh-my-zsh.sh"

    # ohmyzsh plugin history-substring-search
    source /usr/local/share/zsh-history-substring-search/zsh-history-substring-search.zsh

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

    load_src() {
        local files=(
            .kops
            .env
        )

        for file in "${files[@]}"; do
            if [ -f "${file}" ]; then
                echo "found ${file}"
                source "${file}"
            fi
        done
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

    b.() {
        cd "${DOTFILES_PATH}"
    }

    b() {
        case ${1} in
            ".")    b.;;
            *)      cd "${PROJECTS_PATH}/bartsmykla/${1}";;
        esac
    }

    cs() {
        if [[ $# != 1 ]]; then
            echo "cs(command): function expects 1 argument" >&2
            return 1
        fi

        local cmd="${1}"

        curl "cheat.sh/${cmd}"
    }

    kill_port() {
        if (( $# != 1 )); then
            echo "kill_port(port): function expects 1 argument" >&2
            return 1
        fi

        local port="${1}"

        lsof -i ":${port}" -sTCP:LISTEN \
            | awk 'NR > 1 {print $2}' \
            | xargs kill -9
    }

# Key bindings related
    # accepting autosuggestions by using ctrl + space keys
    bindkey '^ ' autosuggest-accept

    bindkey '^U' backward-kill-line

    autoload -Uz copy-earlier-word
    zle -N copy-earlier-word

# Hooks
    add-zsh-hook chpwd load_src

# PATH
    # Binaries from .dotfiles repository
    export PATH="${DOTFILES_PATH}/bin:${PATH}"
    # Custom binaries with superuser privileges required
    export PATH="/usr/local/sbin:${PATH}"
    # Overwrite default MacOS's version of getopt with the proper one
    export PATH="/usr/local/opt/gnu-getopt/bin:${PATH}"
    # OpenJDK
    export PATH="/usr/local/opt/openjdk/bin:${PATH}"

# Secrets
    # Homebrew
    export HOMEBREW_GITHUB_API_TOKEN;
        HOMEBREW_GITHUB_API_TOKEN="$(get_secret HOMEBREW_GITHUB_API_TOKEN)"
    # AWS terraform_learning account
    export AWS_ACCESS_KEY_ID;
        AWS_ACCESS_KEY_ID="$(get_secret AWS_ACCESS_KEY_ID)"
    export AWS_SECRET_ACCESS_KEY;
        AWS_SECRET_ACCESS_KEY="$(get_secret AWS_SECRET_ACCESS_KEY)"

# Aliases:
    alias zshrc="\${EDITOR:=vim} \${ZSHRC:=~/.zshrc}"
    alias hi="/Volumes/fortress/.hi" 
    alias sad="ssh-add /Volumes/fortress/.ssh/fortress1_rsa"
    alias p="cd ${PROJECTS_PATH}"
    alias rem="rm -i"
    alias gcs="git commit -sS"
    alias t="tmuxinator"
    alias td="tmuxinator dev"
    alias kio="cd ${PROJECTS_PATH}/kubernetes/k8s.io"

# Set additional options
    # Extended glob options to be able to use for example negation "^"
    # More: http://zsh.sourceforge.net/Intro/intro_2.html
    setopt extendedglob

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
        export PKG_CONFIG_PATH="/usr/local/opt/ruby/lib/pkgconfig"
        CPPFLAGS+=" -I/usr/local/opt/ruby/include"
    fi

# OpenJDK
    CPPFLAGS+=" -I/usr/local/opt/openjdk/include"

# sdkman
    source "${HOME}/.sdkman/bin/sdkman-init.sh"

# RVM
    source "${HOME}/.rvm/scripts/rvm"

bash "${DOTFILES_PATH}/helper_scripts/ssh-agent.bash" \
    "/Volumes/${VOLUME_NAME}/.ssh/${KEY_NAME}"
source_custom_scripts
load_src

