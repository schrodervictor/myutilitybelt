" search.vim
"
" @package myutilitybelt
" @subpackage vim
" @author Victor Schroder <schrodervictor@gmail.com>
" @author thiagoalessio <thiagoalessio@me.com>

" Incremental searching, shows the matches while typing
" The screen will move a lot, so only useful in fast terminals
" If <Esc> is pressed, will return for the last position before the search
set incsearch

" When there is a previous search pattern, highlight all its matches
set hlsearch

" Ignore case in search patterns by default
set ignorecase

" If the search pattern has any uppercase letter, make the search be
" case sensitive
" When smartcase and ignorecase are turned on, <C-L> (for appending the
" following letter to the current search pattern) will convert that letter
" to lowercase
set smartcase
