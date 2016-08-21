# colors.zsh
#
# @package myutilitybelt
# @subpackage zsh
# @author Victor Schröder <schrodervictor@gmail.com>
# @author thiagoalessio <thiagoalessio@me.com>

autoload colors; colors;
alias grep='grep --color=auto'
export GREP_COLORS='mt=03;33:sl=:cx=:fn=33:ln=32:bn=32:se=36'
export CLICOLOR='auto'
ls --color -d . &>/dev/null 2>&1 && alias ls='ls --color=auto'
