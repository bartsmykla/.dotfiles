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

