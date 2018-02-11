" indentation.vim
"
" @package myutilitybelt
" @subpackage vim
" @author schrodervictor <schrodervictor@gmail.com>

" I prefer to work with spaces instead of tabs
set expandtab

" Using indentation equals to four spaces
" and keeping the same value to shiftwidth,
" softtabstop and tabstop

" tabstop = size of a tab
set tabstop=4

" Amount of white space to add or remove when
" indenting in normal mode
set shiftwidth=4

" softtabstop takes precedence when indenting
" but as we are using spaces, this has no effect.
" When using real tabs, a different value here leads
" to a mix of tabs and spaces
set softtabstop=4

" Copy indent from current line when starting a new line
" using <CR> in insert mode or 'o' or 'O' commands
set autoindent

" Using C-style automatic indentation
" OBS: use cinoptions and cinkeys to alter the indentation behavior
set cindent

" Make some important invisible chars visible
" when list is turned on
set listchars=tab:▸\ ,trail:·,extends:#,nbsp:·,eol:¬

" Specific overrides per filetype
autocmd Filetype javascript call SetIndentation(2)
autocmd Filetype vim call SetIndentation(2)

function SetIndentation(spaces)
  let &l:tabstop = a:spaces
  let &l:shiftwidth = a:spaces
  let &l:softtabstop = a:spaces
endfunction
