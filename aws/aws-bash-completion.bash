_aws-profile() {
    __aws-file-exists "$(__aws-credentials-file)" || return 1

    local PREV CUR PROFILES REGIONS OPTIONS

    PROFILES=( $(__aws-get-all-profiles) )
    REGIONS=( $(__aws-get-all-regions) )
    OPTIONS=( -h --help )

    if ! echo "${COMP_WORDS[*]}" | grep --quiet '\( -r\| --region\)'; then
        OPTIONS+=( -r --region )
    fi

    if ! echo "${COMP_WORDS[*]}" | grep --quiet '\( -p\| --profile\)'; then
        OPTIONS+=( -p --profile )
    fi

    if ! echo "${COMP_WORDS[*]}" | grep --quiet '\( -q\| --quiet\)'; then
        OPTIONS+=( -q --quiet )
    fi

    if ! echo "${COMP_WORDS[*]}" | grep --quiet '\( -m\| --mfa-code\)'; then
        OPTIONS+=( -m --mfa-code )
    fi

    if ! echo "${COMP_WORDS[*]}" | grep --quiet '\( -s\| --mfa-serial\)'; then
        OPTIONS+=( -s --mfa-serial )
    fi

    COMPREPLY=()
    CUR="${COMP_WORDS[COMP_CWORD]}"
    PREV="${COMP_WORDS[COMP_CWORD - 1]}"

    case "$PREV" in
        -h|--help)
            return 0
            ;;
        -p|--profile)
            COMPREPLY=( $(compgen -W "${PROFILES[*]}" -- "$CUR" ) )
            ;;
        -r|--region)
            COMPREPLY=( $(compgen -W "${REGIONS[*]}" -- "$CUR" ) )
            ;;
        -m|--mfa-code|-s|--mfa-serial)
            COMPREPLY=()
            ;;
        *)
            COMPREPLY=( $(compgen -W "${OPTIONS[*]}" -- "$CUR" ) )
            ;;
    esac

    return 0
}

complete -F _aws-profile aws-profile
