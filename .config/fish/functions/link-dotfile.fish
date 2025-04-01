function link_dotfile --description "Symlink a dotfile from \$DOTFILES_PATH to target location, backing up existing file or directory"
    set --local src_rel (string replace --regex "^($HOME/|$DOTFILES_PATH/|~/)" "" "$argv[1]")
    set --local src "$DOTFILES_PATH/$src_rel"
    set --local src_short (string replace "$HOME" "~" "$src")
    set --local dst (test -n "$argv[2"]; and echo "$argv[2]"; or echo "$HOME/$src_rel")
    set --local dst_short (string replace "$HOME" "~" "$dst")
    set --local dst_parent (dirname "$dst")

    if not test -e "$src"
        echo "Source does not exist: $src"
        return 1
    end

    if not test -d "$dst_parent"
        echo "Destination parent does not exist: $dst_parent"
        return 1
    end

    if test -L "$dst"; and test (readlink "$dst") = "$src"
        echo "Symlink already exists: $dst_short → $src_short"
        return 0
    end

    if test -e "$dst"
        set --local timestamp (date +'%d%m%y-%H%M')
        set --local backup "$dst-$timestamp"
        set --local backup_short (string replace "$HOME" "~" "$backup")

        echo "Creating backup:  $dst_short → $backup_short"

        rsync --archive --partial "$dst" "$backup" > /dev/null
        rm --recursive --force "$dst"
    end

    echo "Creating symlink: $src_short → $dst_short"

    ln --symbolic --force --verbose "$src" "$dst" > /dev/null
end
