" seting amount of colors of terminal
  set t_Co=256

" syntax highlighting
  syntax on

" lines number
  set number

" filetype  : vim will try to figure out what is the type of a file
" plugin    : loads the file `ftplugin.vim` in `runtimepath` (when a file is edited its plugin file is loaded [if there is one for the detected filetype])
" indent    : loads the file `indent.vim` in `runtimepath` (when a file is edited its indent file is loaded [if there is one for the detected filetype])
  filetype plugin indent on

" converting tabs into spaces
  set expandtab

" changes the width of the TAB character to 4 spaces
  set tabstop=4

" affects what happens when you press the <TAB> or <BS> keys. Its default value is the same as the value of `tabstop`, but when using indentation without hard tabs or mixed indentation, you want to set it to the same value as `shiftwidth`. If `expandtab` is unset, and `tabstop` is different from `softtabstop`, the <TAB> key will minimize the amount of spaces inserted by using multiples of  TAB characters. For instance, if `tabstop` is 8, and the amount of consecutive space inserted is 20, two  TAB characters and four spaces will be used
  set softtabstop=4

" affects what happens when you press >>, << or ==. It also affects how automatic indentation works.
  set shiftwidth=4

