# vcs.zsh
#
# @package myutilitybelt
# @subpackage zsh
# @author thiagoalessio <thiagoalessio@me.com>

autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git*' formats " on %{$fg[cyan]%}%b%{$reset_color%}"
zstyle ':vcs_info:git*' actionformats " on %{$fg[cyan]%}%b %{$fg[red]%}(%a)%{$reset_color%}"
