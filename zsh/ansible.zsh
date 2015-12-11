# ~/.zshrc
#
# @package myutilitybelt
# @subpackage zsh
# @author Victor Schröder <schrodervictor@gmail.com>

if [ -z "$ANSIBLE_HOME" ]; then
    ANSIBLE_HOME="$HOME/ansible"
fi

source "$ANSIBLE_HOME/hacking/env-setup" -q
