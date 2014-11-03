# prompt.zsh
#
# @package myutilitybelt
# @subpackage zsh
# @author thiagoalessio <thiagoalessio@me.com>

set prompt_subst

precmd() {
    vcs_info

    PROMPT=$'\n'
    PROMPT+="%{$fg[green]%}%D %*%{$reset_color%} "
    PROMPT+="%{$fg[magenta]%}%n%{$reset_color%}"
    PROMPT+='@'
    PROMPT+="%{$fg[yellow]%}%m%{$reset_color%}"
    PROMPT+=' in '
    PROMPT+="%{$fg[green]%}%~%{$reset_color%}"
    PROMPT+="${vcs_info_msg_0_}"
    PROMPT+=$'\n'
    PROMPT+="${VIMODE}"
    PROMPT+="%(?,%{$fg[green]%},%{$fg[red]%})%#%{$reset_color%} "
}

RPROMPT=''
