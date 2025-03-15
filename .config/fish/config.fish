# Homebrew
  eval "$(/opt/homebrew/bin/brew shellenv)"

# vars
  set --export PROJECTS_PATH $HOME/Projects/github.com
  set --export MY_PROJECTS_PATH $PROJECTS_PATH/bartsmykla
  set --export DOTFILES_PATH $MY_PROJECTS_PATH/.dotfiles
  set --export FORTRESS_PATH /Volumes/fortress-carima
  set --export SECRETS_PATH $DOTFILES_PATH/secrets

# fzf
  fzf_configure_bindings \
    --directory=\cf \
    --git_log=\cl \
    --git_status=\cs \
    --processes=\cp

# EDITOR
  set --global --export EDITOR vim

# PATH
  # `bin` directory of .dotfiles repository
  fish_add_path $DOTFILES_PATH/bin
  # `bin` directory on fortress
  fish_add_path $FORTRESS_PATH/.dotfiles/bin
  # rust/cargo
  fish_add_path "$HOME/.cargo/bin"
  # kuma ~/bin directory
  fish_add_path "$HOME/bin"
  # GNU coreutils
  fish_add_path $(brew --prefix)/opt/coreutils/libexec/gnubin
  # krew - kubectl plugin manager
  fish_add_path --append "$HOME/.krew/bin"
  # curl
  fish_add_path /usr/local/opt/curl/bin
  # g-install: do NOT edit, see https://github.com/stefanmaric/g
  fish_add_path "$GOPATH/bin"

# zlib
  set --global --export LDFLAGS "-L/usr/local/opt/zlib/lib"
  set --global --export CPPFLAGS "-I/usr/local/opt/zlib/include"

# ansible
  set --global --export ANSIBLE_CONFIG "$DOTFILES_PATH/ansible/ansible.cfg"

# nvm
  set --global --export nvm_default_version v16.18.0

  [ -f .nvmrc ] || [ -f .node-version ]; \
  and command --query nvm || functions --query nvm;
  and nvm use

# go
  set --global --export GOPATH "$HOME/go"
  set --global --export GOROOT "$HOME/.go"

# gcloud cli tool
  set --global --export USE_GKE_GCLOUD_AUTH_PLUGIN "True"
  source "$(brew --prefix)/share/google-cloud-sdk/path.fish.inc"

# save history before running any command
  function save_history --on-event fish_preexec
      history --save
  end

# install direnv hook (https://direnv.net/docs/hook.html#fish)
  direnv hook fish | source
  set --global direnv_fish_mode eval_on_arrow

# starship prompt
  starship init fish | source

# jump (https://github.com/gsamokovarov/jump)
  jump shell fish | source

# locale
  set --global --export LC_ALL en_US.UTF-8
  set --global --export LANG en_US.UTF-8

# mise
  [ -f $HOME/.local/bin/mise ] && $HOME/.local/bin/mise activate fish | source

