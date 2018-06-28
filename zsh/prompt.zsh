# prompt.zsh
#
# @package myutilitybelt
# @subpackage zsh
# @author Victor Schröder <schrodervictor@gmail.com>

set prompt_subst

precmd() {
    vcs_info

    PROMPT=''
    RPROMPT=''

    PROMPT+=$'\n'
    PROMPT+="%{$fg[green]%}%D %*%{$reset_color%} "
    PROMPT+=$'\n'
    PROMPT+="%{$fg[magenta]%}%n%{$reset_color%}"
    PROMPT+='@'
    PROMPT+="%{$fg[yellow]%}%m%{$reset_color%}"
    PROMPT+=':'
    PROMPT+="%{$fg[green]%}%~%{$reset_color%}"

    if [ -n "$vcs_info_msg_0_" ]; then
        PROMPT+=" [${vcs_info_msg_0_#*on }]"
    fi

    PROMPT+=$'\n'
    PROMPT+="${VIMODE}"
    PROMPT+="%(?,%{$fg[green]%},%{$fg[red]%}[%?] )\$%{$reset_color%} "
}
