set nocompatible
filetype off

set rtp+=$HOME/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

call vundle#end()
filetype plugin indent on

" importing all files (plugins) from plugins directory
runtime! plugins/*.vim
