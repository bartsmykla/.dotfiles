# .dotfiles

```shell
PROJECTS_PATH="${HOME}/Projects/github.com"
MY_PROJECTS_PATH="${PROJECTS_PATH}/bartsmykla"
DOTFILES_REPO="git@github.com:bartsmykla/.dotfiles.git"
DOTFILES_PATH="${MY_PROJECTS_PATH}/.dotfiles"

CASK_FORMULAS=(
    mpv
    xquartz
)

FORMULAS=(
    ack
    ansible
    awscli
    bash
    docker
    fswatch
    git-crypt
    gnu-getopt
    gnu-sed
    gnupg
    go
    hammerspoon
    helm
    jq
    kops
    kubernetes-cli
    lua
    mps-youtube
    shellcheck
    sleepwatcher
    terraform
    tmux
    tmuxinator
    vim
    zsh-history-substring-search 
)

SERVICES_TO_START=(
    sleepwatcher
)

# 'mps-youtube' has a hard dependency of 'xquart' so casks are being installed
# first (maybe in the future we'll improve this a little bit
for formula in "${CASK_FORMULAS[@]}"; do
    brew cask install "${formula}"
done

for formula in "${FORMULAS[@]}"; do
    brew install "${formula}"
done

# TODO: sleepwatcher need to be configured (launchd plist files) before we just
#       start the service, so for now it's commented
# # Start teh service formula and register it to launch at login
# for service in "${SERVICES_TO_START[@]}"; do
#     brew services start "${service}"
# done

# Checking dependencies
! git --version >/dev/null 2>&1 \
    && echo "No git. Exiting" >&2; exit 1
! git-crypt --version  >/dev/null 2>&1 \
    && echo "No git-crypt. Exiting" >&2; exit 1

! [[ -d "${MY_PROJECTS_PATH}" ]] && mkdir -p "${MY_PROJECTS_PATH}"
if ! [[ -d "${DOTFILES_PATH}" ]]; then
    git clone "${DOTFILES_REPO}" "${DOTFILES_PATH}"
    git submodule update --init --recursive
    (cd "${DOTFILES_PATH}"; git-crypt unlock)
    (cd "${DOTFILES_PATH}/oh-my-zsh-custom"; git-crypt unlock)
fi
echo "source ${DOTFILES_PATH}/.zshrc" > ~/.zshrc
source "${DOTFILES_PATH}/.zshrc"

ln -sfv "${DOTFILES_PATH}/.alacritty.yml" ~/.alacritty.yml
ln -sfv "${DOTFILES_PATH}/.tmux.conf" ~/.tmux.conf
ln -sfv "${DOTFILES_PATH}/.config/mps-youtube" ~/.config/mps-youtube
ln -sfv "${DOTFILES_PATH}/.config/tmuxinator" ~/.config/tmuxinator
ln -sfv "${DOTFILES_PATH}/.hammerspoon/init.lua" ~/.hammerspoon/init.lua
ln -sfv "${DOTFILES_PATH}/.gnupg/gpg.conf" ~/.gnupg/gpg.conf
ln -sfv "${DOTFILES_PATH}/.gnupg/gpg-agent.conf" ~/.gnupg/gpg-agent.conf
```

