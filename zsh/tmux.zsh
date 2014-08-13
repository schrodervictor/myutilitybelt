# tmux.zsh
#
# @package myutilitybelt
# @subpackage zsh
# @author thiagoalessio <thiagoalessio@me.com>

alias tmux='tmux -2'

if [[ "$TMUX" == "" ]]; then
    tmux -S ~/.mytmuxsession attach || tmux -S ~/.mytmuxsession
fi