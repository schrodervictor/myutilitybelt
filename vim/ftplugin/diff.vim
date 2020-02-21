autocmd QuitPre diff call ForceQuitIfPullRequest()

function! ForceQuitIfPullRequest()
  if get(g:, 'github_pull_request', 0)
    let orig_confirm = &confirm
    set noconfirm
    execute 'bdelete!'
    let &confirm = orig_confirm
  endif
endfunction
