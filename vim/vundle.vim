" vundle.vim
"
" @package myutilitybelt
" @subpackage vim
" @author schrodervictor <schrodervictor@gmail.com>

" Turn OFF filetype detection is a requirement, before Vundle starts
filetype off

" Tell to runtimepath where Vundle's repo is
set runtimepath+=~/.myutilitybelt/vim/bundle/Vundle.vim

" Begin Vundle, indicating the destination path for plugins
call vundle#begin('~/.vim/bundle/')

" Vundle manages itself, this is required
Plugin 'gmarik/Vundle.vim'

"file browsing
"Plugin 'scrooloose/nerdtree'
"Plugin 'kien/ctrlp.vim'
"Plugin 'majutsushi/tagbar'

"code editing
"Plugin 'Lokaltog/vim-easymotion'
"Plugin 'godlygeek/tabular'
"Plugin 'mbbill/undotree'
"Plugin 'mattn/emmet-vim'
"Plugin 'scrooloose/nerdcommenter'
"Plugin 'garbas/vim-snipmate'
"Plugin 'honza/vim-snippets'
"Plugin 'ervandew/supertab'
"Plugin 'tpope/vim-surround'
"Plugin 'scrooloose/syntastic'

"version control integration
"Plugin 'tpope/vim-fugitive'
"Plugin 'int3/vim-extradite'

"visual/fancy stuff
"Plugin 'bling/vim-airline'
"Plugin 'nanotech/jellybeans.vim'
"Plugin 'Yggdroot/indentLine'

"integration with external programs
"Plugin 'benmills/vimux'

"dependencies
"Plugin 'MarcWeber/vim-addon-mw-utils'
"Plugin 'tomtom/tlib_vim'

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
