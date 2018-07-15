Plugin 'FooSoft/vim-argwrap'

nnoremap <Leader>a 0 f( l :ArgWrap<CR> ])

" As we'll be working mostly with Go code, it's good to add a trailing comma
"   after the last argument
let g:argwrap_tail_comma = 1
