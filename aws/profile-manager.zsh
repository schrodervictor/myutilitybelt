# profile-manager.zsh
#
# @package myutilitybelt
# @subpackage aws
# @author Victor Schröder <schrodervictor@gmail.com>

aws-profile() {
    local QUIET
    local PROFILE
    local REGION
    local MFA_CODE
    local MFA_SERIAL

    local SUCCESS=true

    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                __aws-profile-help
                return 0
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -p|--profile)
                PROFILE="$2"
                shift 2
                ;;
            -r|--region)
                REGION="$2"
                shift 2
                ;;
            -m|--mfa-code)
                MFA_CODE="$2"
                shift 2
                ;;
            -s|--mfa-serial)
                MFA_SERIAL="$2"
                shift 2
                ;;

            # Backwards compatibility with the old positional args
            *)
                if [ -z "$PROFILE" ]; then
                    PROFILE="$1"
                    shift
                    continue
                fi

                if [ -z "$REGION" ]; then
                    REGION="$1"
                    shift
                    continue
                fi
                ;;
        esac
    done

    $QUIET echo -e "\nAWS profile manager by Victor Schröder - 2018\n"

    if [ -z "$PROFILE" ]; then
        # No profile was provided. Output which profile is being used
        __aws-profile-show-info
        return 0
    fi

    if ! __aws-profile-exists "$PROFILE"; then
        $QUIET echo "    [$PROFILE] ERROR: AWS profile not found!!"
        return 1
    fi

    local ASSUMED_PROFILE
    local ROLE_ARN

    if __aws-profile-check-assume-role "$PROFILE"; then
        local ASSUMED_PROFILE="$PROFILE"
        PROFILE="$(__aws-profile-get-source-profile "$ASSUMED_PROFILE")"
        local ROLE_ARN="$(__aws-profile-get-role-arn "$ASSUMED_PROFILE")"

        if [ -z "$PROFILE" ]; then
            $QUIET echo "    [$PROFILE] ERROR: AWS source profile not found!!"
            SUCCESS=false
        fi

        if [ -z "$ROLE_ARN" ]; then
            $QUIET echo "    [$PROFILE] ERROR: role ARN not configured!!"
            SUCCESS=false
        fi

        $SUCCESS || return 1
    fi

    local ACCESS_KEY="$(__aws-profile-get-access-key "$PROFILE")"
    local SECRET_KEY="$(__aws-profile-get-secret-key "$PROFILE")"

    if [ -z "$ACCESS_KEY" ]; then
        $QUIET echo "    [$PROFILE] ERROR: Access key not found!"
        SUCCESS=false
    fi

    if [ -z "$SECRET_KEY" ]; then
        $QUIET echo "    [$PROFILE] ERROR: Secret key not found!"
        SUCCESS=false
    fi

    $SUCCESS || return 1

    local JSON=
    local SESSION_TOKEN=

    if [ -n "$MFA_CODE" ] && [ -z "$MFA_SERIAL" ]; then
        MFA_SERIAL="$(__aws-profile-get-mfa-serial "$PROFILE")"

        if [ -z "$MFA_SERIAL" ] && [ -n "$ASSUMED_PROFILE" ]; then
            MFA_SERIAL="$(__aws-profile-get-mfa-serial "$ASSUMED_PROFILE")"
        fi

        if [ -z "$MFA_SERIAL" ]; then
            $QUIET echo "    [$PROFILE] ERROR: could not locate mfa_serial"
            return 1
        fi
    fi

    if [ -n "$ASSUMED_PROFILE" ]; then
        local ASSUME_ARGS=()
        ASSUME_ARGS+=( "$PROFILE" "$ASSUMED_PROFILE" "$ROLE_ARN" )
        ASSUME_ARGS+=( "$MFA_SERIAL" "$MFA_CODE" )

        JSON="$(__aws-profile-get-assume-role-json "${ASSUME_ARGS[@]}")"

        if [ -z "$JSON" ]; then
            $QUIET echo "    [$PROFILE] ERROR: assume role command failed!"
            return 1
        fi

        unset MFA_CODE MFA_SERIAL
    fi

    if [ -n "$MFA_CODE" ] && [ -n "$MFA_SERIAL" ]; then
        JSON="$(__aws-profile-get-mfa-json "$PROFILE" "$MFA_SERIAL" "$MFA_CODE")"

        if [ -z "$JSON" ]; then
            $QUIET echo "    [$PROFILE] ERROR: MFA authentication failed!"
            return 1
        fi
    fi

    if [ -n "$JSON" ]; then
        ACCESS_KEY="$(echo "$JSON" \
            | sed -n 's/^ *"AccessKeyId" *: *"\([^"]\+\)".*$/\1/p')"

        SECRET_KEY="$(echo "$JSON" \
            | sed -n 's/^ *"SecretAccessKey" *: *"\([^"]\+\)".*$/\1/p')"

        SESSION_TOKEN="$(echo "$JSON" \
            | sed -n 's/^ *"SessionToken" *: *"\([^"]\+\)".*$/\1/p')"
    fi

    if [ -n "$ASSUMED_PROFILE" ]; then
        PROFILE="$ASSUMED_PROFILE"
    fi

    local DEFAULT_REGION="$(__aws-profile-get-region "$PROFILE")"

    if __aws-region-exists "$DEFAULT_REGION"; then
        REGION="${REGION:-$DEFAULT_REGION}"
    fi

    if [ -n "$REGION" ] && ! __aws-region-exists "$REGION"; then
        $QUIET echo "    [$PROFILE] ERROR: region $REGION not found!!"
        return 1
    fi

    aws-clean-environment

    # AWS_PROFILE is enough for aws cli and boto
    export AWS_PROFILE="$PROFILE"
    $QUIET echo "    [$PROFILE] Successfully exported AWS profile"

    export AWS_ACCESS_KEY="$ACCESS_KEY"
    export AWS_ACCESS_KEY_ID="$ACCESS_KEY"

    export AWS_SECRET_KEY="$SECRET_KEY"
    export AWS_SECRET_ACCESS_KEY="$SECRET_KEY"
    $QUIET echo "    [$PROFILE] Successfully exported access/secret keys"

    if [ -n "$SESSION_TOKEN" ]; then
        export AWS_SECURITY_TOKEN="$SESSION_TOKEN"
        export AWS_SESSION_TOKEN="$SESSION_TOKEN"
        $QUIET echo "    [$PROFILE] Successfully exported session token"
    fi

    if [ -n "$DEFAULT_REGION" ]; then
        export AWS_DEFAULT_REGION="$DEFAULT_REGION"
        $QUIET echo "    [$PROFILE] Successfully exported default region ($DEFAULT_REGION)"
    else
        $QUIET echo "    [$PROFILE] Skipped exporting default region"
    fi

    if [ -n "$REGION" ]; then
        # ansible ec2 modules
        export AWS_REGION="$REGION"
        $QUIET echo "    [$PROFILE] Successfully exported region ($REGION)"
    else
        $QUIET echo "    [$PROFILE] Skipped exporting region"
    fi
}

aws-show-environment() {
    printenv | grep --color=never AWS
}

aws-clean-environment() {
    # aws cli and boto
    unset AWS_PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    unset AWS_SECURITY_TOKEN
    unset AWS_DEFAULT_REGION
    unset AWS_REGION
    unset AWS_DEFAULT_PROFILE
    unset AWS_CONFIG_FILE

    # ec2 cli
    unset AWS_CREDENTIALS_CSV
    unset AWS_ACCESS_KEY
    unset AWS_SECRET_KEY
    unset EC2_URL
}

__aws-profile-get-mfa-json() {
    command -v aws >/dev/null 2>&1 || return 1

    local PROFILE="$1"
    local MFA_SERIAL="$2"
    local MFA_CODE="$3"

    if [ -z "$PROFILE" ] || [ -z "$MFA_SERIAL" ] || [ -z "$MFA_CODE" ]; then
        return 1
    fi

    aws-profile --quiet --profile "$PROFILE" || return 1

    aws sts get-session-token \
        --serial-number "$MFA_SERIAL" \
        --token-code "$MFA_CODE" \
        2>/dev/null
}

__aws-profile-get-assume-role-json() {
    command -v aws >/dev/null 2>&1 || return 1

    local PROFILE="$1"
    local ASSUMED_PROFILE="$2"
    local ROLE_ARN="$3"
    local MFA_SERIAL="$4"
    local MFA_CODE="$5"

    if \
        [ -z "$PROFILE" ] \
        || [ -z "$ASSUMED_PROFILE" ] \
        || [ -z "$ROLE_ARN" ]
    then
        return 1
    fi

    aws-profile --quiet --profile "$PROFILE" || return 1

    local AWS_CLI_ARGS=()
    AWS_CLI_ARGS+=( --role-arn "$ROLE_ARN" )
    AWS_CLI_ARGS+=( --role-session-name "$ASSUMED_PROFILE" )

    if [ -n "$MFA_SERIAL" ] && [ -n "$MFA_CODE" ]; then
        AWS_CLI_ARGS+=( --serial-number "$MFA_SERIAL" )
        AWS_CLI_ARGS+=( --token-code "$MFA_CODE" )
    fi

    aws sts assume-role "${AWS_CLI_ARGS[@]}" 2>/dev/null
}

__aws-file-exists() {
    local FILE="$1"
    [ -f "$FILE" ] && ! [ -L "$FILE" ]
}

__aws-credentials-file() {
    echo "$HOME/.aws/credentials"
}

__aws-config-file() {
    echo "$HOME/.aws/config"
}

__aws-profile-exists() {
    __aws-get-all-profiles | grep --quiet "^$1$"
}

__aws-profile-check-assume-role() {
    __aws-profile-get-section "$1" | grep --quiet 'source_profile'
}

__aws-get-all-profiles() {
    local CREDENTIALS_FILE="$(__aws-credentials-file)"
    __aws-file-exists "$CREDENTIALS_FILE" || return 1

    local PROFILES="$(sed -n 's/^\[\(.\+\)\]$/\1/p' "$CREDENTIALS_FILE")"

    local CONFIG_PROFILES
    local CONFIG_FILE="$(__aws-config-file)"

    if __aws-file-exists "$CONFIG_FILE"; then
        CONFIG_PROFILES="$(sed -n 's/^\[profile \(.\+\)\]$/\1/p' "$CONFIG_FILE")"
    fi

    echo -e "$PROFILES\n$CONFIG_PROFILES" | sort -u
}

__aws-profile-get-section() {
    local PROFILE="$1"

    local CREDENTIALS_FILE="$(__aws-credentials-file)"
    __aws-file-exists "$CREDENTIALS_FILE" || return 1

    awk '
        /\[.+\]/ { isSection = 0 };
        /\['"$PROFILE"'\]/ { isSection = 1 };
        isSection == 1 { print }
    ' "$CREDENTIALS_FILE"

    local CONFIG_FILE="$(__aws-config-file)"

    # AWS config file is optional
    __aws-file-exists "$CONFIG_FILE" || return

    awk '
        /\[.+\]/ { isSection = 0 };
        /\[profile '"$PROFILE"'\]/ { isSection = 1 };
        isSection == 1 { print }
    ' "$CONFIG_FILE"
}

__aws-profile-get-mfa-serial() {
    __aws-profile-get-section "$1" \
        | sed -n 's/^ *mfa_serial *= *\([^ ]\+\) *$/\1/p'
}

__aws-profile-get-access-key() {
    __aws-profile-get-section "$1" \
        | sed -n 's/^ *aws_access_key_id *= *\([^ ]\+\) *$/\1/p'
}

__aws-profile-get-secret-key() {
    __aws-profile-get-section "$1" \
        | sed -n 's/^ *aws_secret_access_key *= *\([^ ]\+\) *$/\1/p'
}

__aws-profile-get-region() {
    __aws-profile-get-section "$1" \
        | sed -n 's/^ *region *= *\([^ ]\+\) *$/\1/p'
}

__aws-profile-get-source-profile() {
    __aws-profile-get-section "$1" \
        | sed -n 's/^ *source_profile *= *\([^ ]\+\) *$/\1/p'
}

__aws-profile-get-role-arn() {
    __aws-profile-get-section "$1" \
        | sed -n 's/^ *role_arn *= *\([^ ]\+\) *$/\1/p'
}

__aws-region-exists() {
    [ -n "$1" ] || return 1
    echo " $(__aws-get-all-regions) " | grep --quiet " $1 "
}

__aws-get-all-regions() {
    echo \
        us-east-1 \
        us-east-2 \
        us-west-1 \
        us-west-2 \
        ca-central-1 \
        eu-central-1 \
        eu-west-1 \
        eu-west-2 \
        eu-west-3 \
        ap-northeast-1 \
        ap-northeast-2 \
        ap-northeast-3 \
        ap-southeast-1 \
        ap-southeast-2 \
        ap-south-1 \
        sa-east-1
}

__aws-profile-show-info() {
    cat <<-INFO
	    You are currently using:
	
	    [$AWS_PROFILE] as your AWS profile
	    [$AWS_REGION] as the selected AWS region
	    [$AWS_DEFAULT_REGION] as the AWS default region
	
	To show help info use aws-profile help, --help or -h
INFO
}

__aws-profile-help() {
    cat <<-HELP
	Usage:
	    -h, --help                  Shows this help info
	    -q, --quiet                 Quiet mode (disables output)
	    -p, --profile PROFILE_NAME  The AWS profile name to export
	    -r, --region REGION_CODE    The AWS region code to export
	    -m, --mfa-code CODE         MFA code
	    -s, --mfa-serial SERIAL     Serial of physical or virtual MFA device
	
	Positional arguments (deprecated):
	    First argument              Same as --profile
	    Second argument             Same as --region
	
	Without any arguments:
	                                Shows the current settings
HELP
}
