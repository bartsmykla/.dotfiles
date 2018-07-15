Plugin 'fatih/vim-go'

" Highlight
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1

map <Leader>l :cnext<CR>
map <Leader>k :cprevious<CR>
map <Leader>c :cclose<CR>

let g:go_fmt_autosave = 0
let g:go_metalinter_autosave = 1
let g:go_doc_url = 'https://godoc.org'
