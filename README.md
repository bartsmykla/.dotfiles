# .dotfiles

```shell
PROJECTS_PATH="${HOME}/Projects/github.com"
MY_PROJECTS_PATH="${PROJECTS_PATH}/bartsmykla"
DOTFILES_REPO="git@github.com:bartsmykla/.dotfiles.git"
DOTFILES_PATH="${MY_PROJECTS_PATH}/.dotfiles"

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

ln -sfv "${DOTFILES_PATH}/.alacritty.yml ~/.alacritty.yml
```
