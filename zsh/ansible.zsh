# ~/.zshrc
#
# @package myutilitybelt
# @subpackage zsh
# @author Victor Schröder <schrodervictor@gmail.com>

if [ -z "$ANSIBLE_HOME" ]; then
    ANSIBLE_HOME="$HOME/Projects/community/ansible"
fi

function ansible {
    _source_ansible_if_needed
    command ansible $@
}

function ansible-playbook {
    _source_ansible_if_needed
    command ansible-playbook $@
}

function ansible-vault {
    _source_ansible_if_needed
    command ansible-vault $@
}

function ansible-galaxy {
    _source_ansible_if_needed
    command ansible-galaxy $@
}

ANSIBLE_AVAILABLE=false
ANSIBLE_VENV="$ANSIBLE_HOME/venv/bin/activate"
ANSIBLE_SETUP="$ANSIBLE_HOME/hacking/env-setup"

function _source_ansible_if_needed {
    if ! $ANSIBLE_AVAILABLE; then
        echo 'Sourcing ansible...'
        source "$ANSIBLE_VENV" \
            && source "$ANSIBLE_SETUP" -q \
            && ANSIBLE_AVAILABLE=true
    fi
}
