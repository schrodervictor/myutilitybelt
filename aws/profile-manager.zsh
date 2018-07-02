# profile-manager.zsh
#
# @package myutilitybelt
# @subpackage aws
# @author Victor Schröder <schrodervictor@gmail.com>

function aws-profile() {
    local QUIET
    local PROFILE
    local REGION

    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                __aws-profile-output-help
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

    local ACCESS_KEY="$(__aws-profile-get-access-key "$PROFILE")"
    local SECRET_KEY="$(__aws-profile-get-secret-key "$PROFILE")"

    local SUCCESS=true

    if [ -z "$ACCESS_KEY" ]; then
        $QUIET echo "    [$PROFILE] ERROR: Access key not found!"
        SUCCESS=false
    fi

    if [ -z "$SECRET_KEY" ]; then
        $QUIET echo "    [$PROFILE] ERROR: Secret key not found!"
        SUCCESS=false
    fi

    $SUCCESS || return 1

    DEFAULT_REGION="$(__aws-profile-get-region "$PROFILE")"

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
    export AWS_SECRET_KEY="$SECRET_KEY"
    $QUIET echo "    [$PROFILE] Successfully exported access/secret keys"

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
    local CREDENTIALS_FILE="$(__aws-credentials-file)"
    __aws-file-exists "$CREDENTIALS_FILE" || return 1

    grep --quiet "^\[$1\]$" "$CREDENTIALS_FILE"
}

__aws-get-all-profiles() {
    local CREDENTIALS_FILE="$(__aws-credentials-file)"
    __aws-file-exists "$CREDENTIALS_FILE" || return 1

    sed -n 's/^\[\(.\+\)\]$/\1/p' "$CREDENTIALS_FILE"
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

__aws-profile-get-access-key() {
    local SECTION="$(__aws-profile-get-section "$1")"
    echo "$SECTION" | sed -n 's/^ *aws_access_key_id *= *\([^ ]\+\) *$/\1/p'
}

__aws-profile-get-secret-key() {
    local SECTION="$(__aws-profile-get-section "$1")"
    echo "$SECTION" | sed -n 's/^ *aws_secret_access_key *= *\([^ ]\+\) *$/\1/p'
}

__aws-profile-get-region() {
    local SECTION="$(__aws-profile-get-section "$1")"
    echo "$SECTION" | sed -n 's/^ *region *= *\([^ ]\+\) *$/\1/p'
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

__aws-output-help() {
    cat <<-HELP
	Usage:
	    -h, --help                  Shows this help info
	    -q, --quiet                 Quiet mode (disables output)
	    -p, --profile PROFILE_NAME  The AWS profile name to export
	    -r, --region REGION_CODE    The AWS region code to export
	
	Positional arguments (deprecated):
	    First argument              Same as --profile
	    Second argument             Same as --region
	
	Without any arguments:
	                                Shows the current settings
HELP
}
