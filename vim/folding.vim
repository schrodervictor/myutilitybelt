" folding.vim
"
" @package myutilitybelt
" @subpackage vim
" @author thiagoalessio <thiagoalessio@me.com>

set foldenable
set foldmethod=indent
set foldcolumn=1
set foldlevel=99

noremap <space> @=((foldclosed(line('.')) < 0) ? 'zc' : 'zo')<cr>
