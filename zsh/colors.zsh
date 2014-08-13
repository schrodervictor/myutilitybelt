# colors.zsh
#
# @package myutilitybelt
# @subpackage zsh
# @author thiagoalessio <thiagoalessio@me.com>

autoload colors; colors;
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='4;33'
export CLICOLOR='auto'
ls --color -d . &>/dev/null 2>&1 && alias ls='ls --color=tty' || alias ls='ls -G'