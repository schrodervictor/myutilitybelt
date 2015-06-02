" dvorak.vim
"
" @package myutilitybelt
" @subpackage vim
" @author thiagoalessio <thiagoalessio@me.com>
" @author Victor Schröder <schrodervictor@gmail.com>

" Remapping the basic movement keys to Dvorak's right 'home' position
" We don't need to remap the h key
" noremap h h
noremap t j
noremap n k
noremap s l

" Remapping the semicolon=colon to avoid pressing shift
noremap ; :

" Remapping q: to q; because the list of last commands is very useful
noremap q; q:

" Useful remaps to navigate to the beginning and the end of the line
noremap - $
noremap _ ^

" Since we are going to use the 'n' key to navigate, we need another key
" for the search results.
" Let's take the chance and append 'zz' to the command, so the search result
" will be centralized on the window.
noremap k nzz
noremap K Nzz
