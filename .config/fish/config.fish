# vars
  set --export PROJECTS_PATH $HOME/Projects/github.com
  set --export MY_PROJECTS_PATH $PROJECTS_PATH/bartsmykla
  set --export DOTFILES_PATH $MY_PROJECTS_PATH/.dotfiles
  set --export FORTRESS_PATH /Volumes/fortress-carima

# autojump 
[ -f /usr/local/share/autojump/autojump.fish ]; and source /usr/local/share/autojump/autojump.fish

# key bindings
  # https://github.com/fish-shell/fish-shell/issues/3189
  # nul is a name of `Ctrl + Space` key binding
  bind -k nul forward-char

# fzf
  export FZF_DEFAULT_OPTS="--bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all"

# EDITOR
  export EDITOR="vim"

# PATH
  # `bin` directory of .dotfiles repository 
  set -gx PATH $PATH $DOTFILES_PATH/bin
  # `bin` directory on fortress
  set -gx PATH $PATH $FORTRESS_PATH/.dotfiles/bin
  # rust/cargo
  set -gx PATH "$HOME/.cargo/bin" $PATH
  # kuma ~/bin directory
  set -gx PATH $PATH ~/bin
  # GNU coreutils
  set -gx PATH /usr/local/opt/coreutils/libexec/gnubin $PATH

# ansible
  set -gx ANSIBLE_CONFIG $DOTFILES_PATH/ansible/ansible.cfg

# nvm
  set -gx nvm_default_version 15.4.0

# go
  set -gx GOPATH $HOME/go;
  set -gx GOROOT $HOME/.go;
  set -gx PATH $GOPATH/bin $PATH; # g-install: do NOT edit, see https://github.com/stefanmaric/g

# gcloud cli tool
   source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.fish.inc
