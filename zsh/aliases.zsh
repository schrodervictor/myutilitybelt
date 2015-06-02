# aliases.zsh
#
# @package myutilitybelt
# @subpackage zsh
# @author thiagoalessio <thiagoalessio@me.com>

alias c='clear'
alias l='ls -a'
alias ll='ls -lsha'
alias mkdir='mkdir -p'
alias vi='vim'
alias cal='cal | grep --before-context 6 --after-context 6 --color -e "$(date +%e)" -e "^$(date +%e)"'
alias gl='git log --graph --pretty=format:'\''%Cred%h%Creset -%C(yellow)%d%Creset %Cblue%an%Creset - %s %Cgreen(%cr)%Creset'\'' --abbrev-commit --date=relative'
alias etc="etc_git_control"
