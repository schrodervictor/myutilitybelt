" vundle.vim
"
" @package myutilitybelt
" @subpackage vim
" @author schrodervictor <schrodervictor@gmail.com>

" Turn OFF filetype detection is a requirement, before Vundle starts
filetype off

" Tell to runtimepath where Vundle's repo is
set runtimepath+=~/.vim/bundle/Vundle.vim

" Begin Vundle, indicating the destination path for plugins
call vundle#begin('~/.vim/bundle/')

" Vundle manages itself, this is required
Plugin 'gmarik/Vundle.vim'

"visual/fancy stuff
Plugin 'bling/vim-airline'
Plugin 'nanotech/jellybeans.vim'

" Elixir
Plugin 'elixir-editors/vim-elixir'

call vundle#end()

" Turn the filetype detection ON again
" And triggers the FileType autocommand event,
" in this case calling everything that is marked
" for filetypeplugin and filetypeindent
filetype plugin indent on

command! BundleCleanInstallQuit :call s:BundleCleanInstallQuit()
function! s:BundleCleanInstallQuit()
    :BundleClean
    :BundleInstall
    :q
    :q
endfunction
