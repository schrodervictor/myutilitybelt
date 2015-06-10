# tmux.zsh
#
# @package myutilitybelt
# @subpackage zsh
# @author thiagoalessio <thiagoalessio@me.com>
# @author Victor Schröder <schrodervictor@gmail.com>

# Force tmux to assume the terminal supports 256 colours
alias tmux='tmux -2'

# Check if the TMUX variable is empty. If so, we assume that we are not inside
# a Tmux session (beware nested sessions...)
# Zsh is also set as the default shell for Tmux. So, from Bash, running
# zsh command will leave us inside this specific tmux session by default.
if [[ "$TMUX" == "" ]]; then

    # Tries to attach to our custom session socket, if found.
    # If it's not there, create it.
    tmux -S ~/.mytmuxsession attach || tmux -S ~/.mytmuxsession
fi
