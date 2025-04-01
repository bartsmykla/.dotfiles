# Disable initial welcome message
  set --global fish_greeting

# Homebrew
  /opt/homebrew/bin/brew shellenv | source

# vars
  set --export PROJECTS_PATH $HOME/Projects/github.com
  set --export MY_PROJECTS_PATH $PROJECTS_PATH/bartsmykla
  set --export DOTFILES_PATH $MY_PROJECTS_PATH/.dotfiles
  set --export FORTRESS_PATH /Volumes/fortress-carima
  set --export SECRETS_PATH $DOTFILES_PATH/secrets

# # fzf
#   fzf_configure_bindings \
#     --directory=\cf \
#     --git_log=\co \
#     --git_status=\cs \
#     --processes=\cp
#
#   set fzf_history_opts --layout=default --algo=v2

# EDITOR
  set --global --export EDITOR vim

# PATH
  # `bin` directory on fortress
  fish_add_path --global --move $FORTRESS_PATH/.dotfiles/bin
  # rust/cargo
  fish_add_path --global --move "$HOME/.cargo/bin"
  # kuma ~/bin directory
  fish_add_path --global --move "$HOME/bin"
  # GNU coreutils
  fish_add_path --global --move "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
  # krew - kubectl plugin manager
  fish_add_path --global --append "$HOME/.krew/bin"

# zlib
  set --global --export LDFLAGS "-L/usr/local/opt/zlib/lib"
  set --global --export CPPFLAGS "-I/usr/local/opt/zlib/include"

# ansible
  set --global --export ANSIBLE_CONFIG "$DOTFILES_PATH/ansible/ansible.cfg"

# gcloud cli tool
  set --global --export USE_GKE_GCLOUD_AUTH_PLUGIN "True"
  source "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.fish.inc"

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

# 1password
  set --global --export SSH_AUTH_SOCK "$HOME/.1password/agent.sock"

# teleport
  # teleport is not working well with 1password when $SSH_AUTH_SOCK is specified
  set --global --export TELEPORT_USE_LOCAL_SSH_AGENT false

# Atuin
  atuin init fish | source
