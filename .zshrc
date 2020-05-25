# TODO: Check dependencies (awk, grep)

# Vars
    export PROJECTS_PATH="${HOME}/Projects/github.com"
    readonly DOTFILES_PATH="${PROJECTS_PATH}/bartsmykla/.dotfiles"
    readonly CUSTOM_SCRIPTS_PATH="${DOTFILES_PATH}/autoload_scripts"
    readonly SECRETS_PATH="${DOTFILES_PATH}/secrets"
    readonly ZSHRC="${DOTFILES_PATH}/.zshrc"
    export NVM_DIR="${HOME}/.nvm"
    export ZSH="${HOME}/.oh-my-zsh"
    export CPPFLAGS=""
    readonly VOLUME_NAME="fortress"
    readonly KEY_NAME="fortress1_rsa"
    readonly KEY_FILE="/Volumes/${VOLUME_NAME}/.ssh/${KEY_NAME}"
    export EDITOR="vim"

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

    get_ssh_hash() {
        local line;

        if [[ $# == 1 ]]; then
            line="${1}"
        elif [[ $# -gt 1 ]]; then
            echo -n "get_hash: to many parameters passed (function expects" >&2
            echo    " 1 parameter OR input to be provided via STDIN [eg." >&2
            echo    " cat \"path_to_key.pub\" | get_hash]" >&2
            return 1
        else
            read line
        fi

        echo "${line}" | awk '{ print $2 }'
    }

    # Function which is checking in ssh agent if our main identity is there
    # present and if not or if its fingerprint doesn't match adding it
    # Arguments:
    #   None
    # Globals:
    #   KEY_FILE
    # Dependencies:
    #   ssh-keygen
    #   ssh-add
    #   grep
    #
    #   get_ssh_hash
    add_identity_maybe() {
        # KEY_FILE exists and isn't empty
        if ! [[ -s "${KEY_FILE}" ]]; then
            echo -n "add_identity: KEYFILE (${KEY_FILE}) doesn't exist or" >&2
            echo    " is empty. Skipping" >&2
            return 1
        fi

        local key_hash;
            key_hash="$(ssh-keygen -lf "${KEY_FILE}" | get_ssh_hash)"
        if [[ $? != 0 ]]; then
            echo -n "add_identity: couldn't get hash fingerprint from" >&2
            echo    " KEY_FILE (${KEY_FILE}). Exiting" >&2
            return 1
        elif [[ -z "${key_hash}" ]]; then
            echo -n "add_identity: something went wrong when trying to" >&2
            echo    " get hash fingerprint from KEY_FILE (${KEY_FILE})" >&2
            echo    " and looks like it's empty" >&2
            return 1
        fi

        local agent_hash;
            agent_hash="$(ssh-add -l | grep "${KEY_FILE}" \
                | get_ssh_hash 2>/dev/null)"

        if [[ $? != 0 ]] || [[ -z "${agent_hash}" ]]; then
            echo "No identity (${KEY_FILE}) found in ssh agent. Adding"
        elif [[ "${key_hash}" != "${agent_hash}" ]]; then
            echo -n "Found identity (${KEY_FILE}) in ssh agent, but"
            echo    " fingerprints don't match"
            echo -e "   key:\t${key_hash}"
            echo -e "   agent:\t${agent_hash}"
            echo    "Adding identity"
        else
            return 0
        fi

        ssh-add "${KEY_FILE}"
    }

# Key bindings related
    # Skip forward/back a word with opt-arrow
    bindkey '[C' forward-word
    bindkey '[D' backward-word

    # accepting autosuggestions by using ctrl + space keys
    bindkey '^ ' autosuggest-accept

    bindkey '^U' backward-kill-line

    autoload -Uz copy-earlier-word
    zle -N copy-earlier-word

# Hooks
    add-zsh-hook chpwd load_src

# PATH
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

add_identity_maybe
source_custom_scripts
load_src
