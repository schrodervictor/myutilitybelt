setlocal foldmethod=expr foldexpr=DiffFold(v:lnum)

autocmd QuitPre diff call ForceQuitIfPullRequest()

function! ForceQuitIfPullRequest()
  if get(g:, 'github_pull_request', 0)
    let orig_confirm = &confirm
    set noconfirm
    execute 'bdelete!'
    let &confirm = orig_confirm
  endif
endfunction

function! DiffFold(lnum)
  let line = getline(a:lnum)
  if line =~ '^\(diff \|#\)'
    return 0
  else
    return 1
  endif
endfunction
