" mappings.vim
"
" @package myutilitybelt
" @subpackage vim
" @author thiagoalessio <thiagoalessio@me.com>

let mapleader=','

"new tab
nnoremap <c-t> :tabnew<cr>

"quick save
map <c-h> :w<cr>
imap <c-h> <esc> :w<cr>

"sudo saving
command! W w !sudo tee %
