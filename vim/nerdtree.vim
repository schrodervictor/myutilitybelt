" nerdtree.vim
"
" @package myutilitybelt
" @subpackage vim
" @author thiagoalessio <thiagoalessio@me.com>

nmap <c-n> :NERDTreeToggle<cr>
imap <c-n> <esc> :NERDTreeToggle<cr>
nmap <c-l> :NERDTreeFind<cr>
imap <c-l> <esc> :NERDTreeFind<cr>

let g:NERDTreeMapJumpParent = 'h'
let g:NERDTreeMapJumpFirstChild = 's'
let g:NERDTreeMapJumpLastChild = 'T'
let g:NERDTreeMapJumpPrevSibling = 'n'
let g:NERDTreeMapJumpNextSibling = 't'
let g:NERDTreeMapOpenInTab = 'ot'
let g:NERDTreeMapOpenInTabSilent = 'ost'
let g:NERDTreeMapOpenSplit = 'oh'
let g:NERDTreeMapOpenVSplit = 'ov'

" function DvorakDown()
"     normal! j
" endfunction
" 
" function DvorakUp()
"     normal! k
" endfunction

augroup NERDTreeDvorak
    autocmd!
    autocmd BufEnter NER* nnoremap <buffer> h h
    autocmd BufEnter NER* nnoremap <buffer> t j
    autocmd BufEnter NER* nnoremap <buffer> n k
    autocmd BufEnter NER* nnoremap <buffer> s l
"    if exists("NERDTreeAddKeyMap")
"     autocmd BufEnter NERD* :call NERDTreeAddKeyMap({ 'key': 'n', 'scope': "all", 'callback': 'DvorakUp' })
"     autocmd BufEnter NERD* :call NERDTreeAddKeyMap({ 'key': 't', 'scope': "all", 'callback': 'DvorakDown' })
"    endif
augroup END
