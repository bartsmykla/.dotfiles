"seting amount of colors of terminal
set t_Co=256

if !exists('g:not_finish_vimplug')
  colorscheme molokai
endif

" lines number
set number

" filetype  : vim will try to figure out what is the type of a file
" plugin    : loads the file `ftplugin.vim` in `runtimepath` (when a file is
"             edited its plugin file
"             is loaded [if there is one for the detected filetype])
" indent    : loads the file `indent.vim` in `runtimepath` (when a file is
"             edited its indent file 
"             is loaded [if there is one for the detected filetype])
" filetype plugin indent on // commented because it's already set by vundle

" converting tabs into spaces
set expandtab

" changes the width of the TAB character to 4 spaces
set tabstop=4

" affects what happens when you press the <TAB> or <BS> keys. Its default
"   value is the same as the value of `tabstop`, but when using indentation
"   without hard tabs or mixed indentation, you want to set it to the same
"   value as `shiftwidth`. If `expandtab` is unset, and `tabstop` is different
"   from `softtabstop`, the <TAB> key will minimize the amount of spaces
"   inserted by using multiples of TAB characters. For instance, if `tabstop`
"   is 8, and the amount of consecutive space inserted is 20, two 
"   TAB characters and four spaces will be used
set softtabstop=4

" affects what happens when you press >>, << or ==. It also affects how
"   automatic indentation works.
set shiftwidth=4

" highlighting search results 
set hlsearch

" turning on line numbers in the left column and when you are moving cursor
"   all lines are relative to the line your cursor is at
set number relativenumber

" setting grey vertical line at 80th character, to be sure that maximum width
"   of a line is 80 characters
set colorcolumn=80
set textwidth=80

" mapping <Shift> + <Tab> to `unindent`
"" for command mode
nnoremap <S-Tab> <<
"" for insert mode
inoremap <S-Tab> <C-d>

" Make backspace work normally
set backspace=indent,eol,start

" clear highlight
nmap // :noh<cr>
vmap // :noh<cr>

" Folding
set nocompatible

filetype plugin indent on

set foldenable
set foldmethod=marker

au FileType sh let g:sh_fold_enabled=5
au FileType sh let g:is_bash=1
au FileType sh set foldmethod=syntax

" syntax highlighting
syntax enable

" Jump to the last position when reopening a file
if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") 
    \&& &filetype != "gitcommit"
    \| exe "normal! g'\"" | endif
endif
