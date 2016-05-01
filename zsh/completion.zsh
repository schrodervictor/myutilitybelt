# completion.zsh
#
# @package myutilitybelt
# @subpackage zsh
# @author thiagoalessio <thiagoalessio@me.com>

autoload -U compinit
compinit -i
autoload -U +X bashcompinit && bashcompinit
source "$HOME/.myutilitybelt/aws/aws-bash-completion.bash"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
