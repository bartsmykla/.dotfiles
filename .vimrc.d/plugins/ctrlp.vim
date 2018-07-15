Plugin 'kien/ctrlp.vim'

" work with hidden files (.dotfiles etc.)
let g:ctrlp_show_hidden = 1
let g:ctrlp_reuse_window = 'netrw\|help|quickfix'

if executable('ag')
  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command = 'ag %s --ignore-case --files-with-matches' +
    ' --nocolor --nogroup -g ""'

  " ag is fast enough that CtrlP doesn't need to cache
  let g:ctrlp_use_caching = 0
  " let g:ctrlp_clear_cache_on_exit = 0

  " 'c' - the directory of the current file.
  " 'a' - the directory of the current file, unless it is a subdirectory
  "       of the cwd
  " 'r' - the nearest ancestor of the current file that contains one of these
  "       directories or files: .git .hg .svn .bzr _darcs
  " 'w' - modifier to "r": start search from the cwd instead of the current
  "       file's directory
  " 0 or '' (empty string) - disable this feature.
  let g:ctrlp_working_path_mode = 'ra'
else
  " Fall back to using git ls-files if Ag is not available
  let g:ctrlp_user_command = [
    \ '.git',
    \ 'cd %s && git ls-files . --cached --exclude-standard --others'
  \ ]
endif

nmap <Leader>o :CtrlP<Space>
nmap <Leader>p :CtrlPBuffer

" Easier buffer navigation, \b
nnoremap <Leader>b :ls<CR>:b<Space>
nnoremap <Leader>e :b<Space>#<CR>

nnoremap <Leader>l :CtrlPLine<CR>
