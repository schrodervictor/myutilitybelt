" mappings.vim
"
" @package myutilitybelt
" @subpackage vim
" @author thiagoalessio <thiagoalessio@me.com>
" @author Victor Schröder <schrodervictor@gmail.com>

" set a more convenient leader key
let mapleader=','

" and why not a local leader key too!
let maplocalleader='\'

" sudo saving. Who never opened a protected file without sudo?
command! W w !sudo tee %

" disables key arrows, because life is too easy
" in normal, visual+select and operator-pending modes
noremap <Left> <nop>
noremap <Right> <nop>
noremap <Up> <nop>
noremap <Down> <nop>

" makes editing the command line more similar to Bash
" the '^[' below are literal Esc chars (Ctrl-V then Esc)
" this is needed to Alt-b and Alt-f to work in the remap
cnoremap <C-a> <Home>
cnoremap <C-e> <End>
set <M-b>=b
cnoremap <M-b> <S-Left>
set <M-f>=f
cnoremap <M-f> <S-Right>

" Sometimes you just remember something and wnat to add it fast
" the following command will open this file quickly
" ev = (e)dit (v)imrc
nnoremap <leader>ev :tabedit $MYVIMRC<cr>

" And here a fast command to source it again
" sv = (s)ource (v)imrc
nnoremap <leader>sv :source $MYVIMRC<cr>

" A better way to cycle between buffers
noremap <leader>n :bnext<cr>
noremap <leader>t :bprevious<cr>

" Faster way to delete a buffer
noremap <leader>bd :bdelete<cr>

" Convertion from timestamp to Date
function! ConvertTimestampToDate()
  execute "normal! viwd"
  let date_string = strftime('%c', @@)
  execute "normal! i" . date_string
endfunction

nnoremap <leader>d :call ConvertTimestampToDate() <CR>
