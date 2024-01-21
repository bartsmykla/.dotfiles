" Weird error message appeared without that
" (https://github.com/vim/vim/issues/3117)
if has('python3')
  silent! python3 1
endif

" remapping <Leader> to <,>
let mapleader=","
let maplocalleader=","

set rtp+=$DOTFILES_PATH/.vimrc.d

runtime vundle.vim
runtime native.vim
runtime auto_set_paste.vim
