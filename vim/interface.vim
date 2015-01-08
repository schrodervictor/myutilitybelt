" interface.vim
"
" @package myutilitybelt
" @subpackage vim
" @author thiagoalessio <thiagoalessio@me.com>
" @author Victor Schröder <schrodervictor@gmail.com>

" wrap long lines to fit the window.
" Don't really wraps the contents, only the display
set wrap

" Turn confirmation ON for operations
" that would normally fail
set confirm

" Turn the ruler ON to show the line, column and relative position
" If rulerformat is defined, will use that format
set ruler

" Show line numbers
set number

" Show relative line numbers
" Very usefull with motions
set relativenumber

" set list ON to show invisible chars
set list

" Define the signs that will be used for the invisible chars
" when list is turned on.
set listchars=eol:¬,trail:.,tab:\|_

" Turn wildmenu ON (autocompletion menu)
set wildmenu

" Best combination for wildmode (autocompletion)
" longest:full = will complete to the longest common substring
"                in the matches. The :full will also start the
"                wildmenu but not highlight anything.
" full = we need to specify full as the second mode to allow
"        cycling between the matches with successive tabs
set wildmode=longest:full,full

" Define some file patterns to ignore for autocompletion
set wildignore=*.o,*.obj,*~

" Using line and column cursors for easy location
set cursorline
set cursorcolumn

" Put a column marker at the given position to
" advice when we are writing too much
set colorcolumn=78

" When a (), [] or {} is inserted, briefly jumps to the correspondent
" pair, when it is visible on the screen
set showmatch

" Shows information about the command we are performing.
" Depends on the mode we are:
"    - Normal mode: displays the partial command typed so far
"    - Visual mode:
"        - selecting chars: # of chars (and # of bytes if different)
"        - selecting lines: # of lines
"        - selecting block: # of lines x # of columns
set showcmd
set laststatus=2
set splitbelow
set splitright
