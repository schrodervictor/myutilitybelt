_aws-profile() {

    _aws-file-exists "$HOME/.aws/credentials"

    if [[ $? -ne 0 ]]; then
        return 1
    fi

    local CUR PROFILES REGIONS

    PROFILES=( $(_aws-get-all-profiles) )
    REGIONS=( $(_aws-get-all-regions) )
    COMPREPLY=()
    CUR="${COMP_WORDS[COMP_CWORD]}"

    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=( $(compgen -W "${PROFILES[*]}" -- "$CUR" ) )
    elif [ $COMP_CWORD -eq 2 ]; then
        COMPREPLY=( $(compgen -W "${REGIONS[*]}" -- "$CUR" ) )
    fi

    return 0
}
complete -F _aws-profile aws-profile
