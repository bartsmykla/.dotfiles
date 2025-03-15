# .dotfiles

## Turn off macOS' conflicting keyboard shortcuts

1. Open `System Settings` > `Keyboard`

   ```sh
   open -b com.apple.systempreferences /System/Library/PreferencePanes/Keyboard.prefPane
   ```

2. Open `Keyboard Shortcuts`

   1. `Ctrl + Space` (This shortcut it going to be used [to accept autosuggestion](https://github.com/bartsmykla/.dotfiles/blob/5a1fc97ea48b4e9419d602fe96752e8cc47b3855/.config/fish/functions/fish_user_key_bindings.fish#L4) in fish)

      1. Go to `Input Sources` tab

         <details>
             <summary>Show Screenshot</summary>
             <img src="https://github.com/bartsmykla/.dotfiles/assets/11655498/a8e5c5d0-80fb-47f1-a2cd-25b754c8edf4" alt="System Settings > Keybord > Keyboard Shortcuts > Input Sources" />
         </details>

      2. Unselect shortcuts
          
         | Description                      | Shortcut  |
         |----------------------------------|-----------|
         | Select the previous input source | `⌃Space`  |
         | Select next source in input menu | `⌃⌥Space` |

   2. `Cmd + Space` (This shortcut is being used by Alfred)

      1. Go to `Spotlight` tab

         <details>
             <summary>Show Screenshot</summary>
             <img src="https://github.com/bartsmykla/.dotfiles/assets/11655498/bfc0764d-f07a-48ee-aff2-365262bb6d8e" alt="System Settings > Keybord > Keyboard Shortcuts > Spotlight" />
         </details>

      2. Unselect shortcuts
          
         | Description               | Shortcut  |
         |---------------------------|-----------|
         | Show Spotlight search     | `⌘Space`  |
         | Show Finder search window | `⌥⌘Space` |

## Install tools

```sh
set --export --global PROJECTS_PATH "$HOME/Projects/github.com"
set --export --global MY_PROJECTS_PATH "$PROJECTS_PATH/bartsmykla"
set --export --global DOTFILES_REPO "git@github.com:bartsmykla/.dotfiles.git"
set --export --global DOTFILES_PATH "$MY_PROJECTS_PATH/.dotfiles"

set --local TAPS \
    homebrew/cask-fonts \
    homebrew/cask-versions \
    helm/tap \

set --local CASK_FORMULAS \
    alacritty \
    alfred \
    discord \
    firefox-developer-edition \
    font-fira-code \
    font-fira-code-nerd-font \
    google-cloud-sdk \
    gpg-suite \
    jetbrains-toolbox \
    obsidian \
    rectangle \
    send-to-kindle \
    signal \

set --local FORMULAS \
    ack \
    awscli \
    bash \
    bat \
    broot \
    chart-releaser \
    coreutils \
    direnv \
    docker \
    docker-completion \
    eza \
    fd \
    fish \
    fzf \
    gh \
    git-crypt \
    gnu-sed \
    gnu-tar \
    gnupg \
    gnutls \
    helm \
    jq \
    jump \
    k3d \
    k9s \
    kubernetes-cli \
    lua \
    mutagen \
    orbstack \
    saml2aws \
    shellcheck \
    starship \
    terraform \
    tmux \
    tmuxp \
    vim \
    yq \

for tap in $TAPS
    brew tap "$tap"
end

for formula in $CASK_FORMULAS
    brew install --cask "$formula"
end

for formula in $FORMULAS
    brew install "$formula"
end

# Checking dependencies
! git --version >/dev/null 2>&1 \
    && echo "No git. Exiting" >&2; exit 1
! git-crypt --version  >/dev/null 2>&1 \
    && echo "No git-crypt. Exiting" >&2; exit 1

! [[ -d "$MY_PROJECTS_PATH" ]] && mkdir -p "$MY_PROJECTS_PATH"
if ! [[ -d "$DOTFILES_PATH" ]]; then
    git clone "$DOTFILES_REPO" "$DOTFILES_PATH"
    git submodule update --init --recursive
    (cd "$DOTFILES_PATH"; git-crypt unlock)
fi

ln --symbolic --force --verbose "$DOTFILES_PATH/.tmux" ~/.tmux
ln --symbolic --force --verbose "$DOTFILES_PATH/.tmux.conf" ~/.tmux.conf
ln --symbolic --force --verbose "$DOTFILES_PATH/.vim" ~/.vim
ln --symbolic --force --verbose "$DOTFILES_PATH/.vimrc" ~/.vimrc
# ~/.config
ln --symbolic --force --verbose "$DOTFILES_PATH/.config/starship.toml" ~/.config/starship.toml
ln --symbolic --force --verbose "$DOTFILES_PATH/.config/alacritty" ~/.config/alacritty
ln --symbolic --force --verbose "$DOTFILES_PATH/.config/broot" ~/.config/broot
ln --symbolic --force --verbose "$DOTFILES_PATH/.config/exercism" ~/.config/exercism
ln --symbolic --force --verbose "$DOTFILES_PATH/.config/k9s" ~/.config/k9s
ln --symbolic --force --verbose "$DOTFILES_PATH/.config/tmuxinator" ~/.config/tmuxinator
ln --symbolic --force --verbose "$DOTFILES_PATH/.config/tmuxp" ~/.config/tmuxp
# ~/.gnupg
ln --symbolic --force --verbose "$DOTFILES_PATH/.gnupg/gpg-agent.conf" ~/.gnupg/gpg-agent.conf
ln --symbolic --force --verbose "$DOTFILES_PATH/.gnupg/gpg.conf" ~/.gnupg/gpg.conf

git config --global gpg.program /usr/local/MacGPG2/bin/gpg2
```

### Install mise

```sh
curl https://mise.run | sh
```

### Install [krew](https://krew.sigs.k8s.io)

```sh
# https://krew.sigs.k8s.io/docs/user-guide/setup/install/#fish
begin
  set -x; set temp_dir (mktemp -d); cd "$temp_dir" &&
  set OS (uname | tr '[:upper:]' '[:lower:]') &&
  set ARCH (uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/') &&
  set KREW krew-$OS"_"$ARCH &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/$KREW.tar.gz" &&
  tar zxvf $KREW.tar.gz &&
  ./$KREW install krew &&
  set -e KREW temp_dir &&
  cd -
end
```

## Install rust

From https://www.rust-lang.org/tools/install

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Show only active apps in macOS' dock

```sh
defaults write com.apple.dock static-only -bool true; killall Dock
```
