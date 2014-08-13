# vi-mode.zsh
#
# @package myutilitybelt
# @subpackage zsh
# @author thiagoalessio <thiagoalessio@me.com>

bindkey -v
export KEYTIMEOUT=1

bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward

zle -N edit-command-line
autoload -Uz edit-command-line
bindkey -M vicmd 'v' edit-command-line

function zle-line-init {
  zle reset-prompt
}

function zle-line-init zle-keymap-select {
    NORMAL_MODE="%{$fg[blue]%}-- NORMAL --%{$reset_color%}"
    INSERT_MODE="%{$fg[green]%}-- INSERT --%{$reset_color%}"
    RPROMPT="${${KEYMAP/vicmd/$NORMAL_MODE}/(main|viins)/$INSERT_MODE}"
    zle reset-prompt
}

zle -N zle-line-init
zle -N zle-keymap-select
