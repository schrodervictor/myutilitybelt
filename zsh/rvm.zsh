# ~/.zshrc
#
# @package myutilitybelt
# @subpackage zsh
# @author Victor Schröder <schrodervictor@gmail.com>

# Activate RVM if present
if [ -s "$HOME/.rvm/scripts/rvm" ]; then
    source "$HOME/.rvm/scripts/rvm"

    # Add RVM to PATH for scripting
    export PATH="$HOME/.rvm/bin:$PATH"
fi
