# profile-manager.zsh
#
# @package myutilitybelt
# @subpackage aws
# @author Victor Schröder <schrodervictor@gmail.com>

aws-profile() {

    if _aws-profile-exists "$1"; then

        aws-clean-environment

        # aws cli and boto
        export AWS_PROFILE="$1"

        # ec2 cli
        read -r AWS_ACCESS_KEY AWS_SECRET_KEY <<< $(_aws-get-access-and-secret-key "$1")
        export AWS_ACCESS_KEY
        export AWS_SECRET_KEY

    else
        echo "AWS profile not found!!"
        return 1
    fi

    if [[ -z "$2" ]]; then

        # ec2 cli
        local AWS_REGION
        AWS_REGION=$(_aws-get-ec2-url-for-profile "$1")
        EC2_URL="https://ec2.${AWS_REGION}.amazonaws.com"
        export EC2_URL

    elif _aws-region-exists "$2"; then

        # aws cli and boto
        AWS_DEFAULT_REGION="$2"
        export AWS_DEFAULT_REGION

        # ec2 cli
        EC2_URL="https://ec2.${2}.amazonaws.com"
        export EC2_URL

    else
        echo "AWS region not found!!\n(but your credentials variables were exported)"
        return 1
    fi

}

aws-clean-environment() {

    # aws cli and boto
    unset AWS_PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    unset AWS_DEFAULT_REGION
    unset AWS_DEFAULT_PROFILE
    unset AWS_CONFIG_FILE

    # ec2 cli
    #unset AWS_CREDENTIALS_CSV
    unset AWS_ACCESS_KEY
    unset AWS_SECRET_KEY
    unset EC2_URL

}

_aws-file-exists() {

    if [[ ! -f "$1" ]] || [[ -L "$1" ]]; then
        return 1
    else
        return 0
    fi

}

_aws-profile-exists() {

    local AWS_CREDENTIALS_FILE="$HOME/.aws/credentials"

    if _aws-file-exists "$AWS_CREDENTIALS_FILE"; then

        local REGEX="^\[$1\]$"
        grep --quiet "$REGEX" "$AWS_CREDENTIALS_FILE"
        return $?

    else
        return 1
    fi
}

_aws-get-all-profiles() {

    local AWS_CREDENTIALS_FILE="$HOME/.aws/credentials"

    awk '/\[.+\]/ { gsub(/[\[|\]]/, ""); print };' "$AWS_CREDENTIALS_FILE"
}

_aws-get-access-and-secret-key() {

    local ACCESS_KEY
    local SECRET_KEY
    local GREP_OUTPUT
    local LINE

    local AWS_CREDENTIALS_FILE="$HOME/.aws/credentials"

    local REGEX="^\[$1\]$"

    GREP_OUTPUT=$(grep -A2 "$REGEX" "$AWS_CREDENTIALS_FILE")

    while read -r LINE; do
        if echo "$LINE" | grep --quiet 'aws_access_key_id'; then
            ACCESS_KEY=$(expr "$LINE" : '^aws\_access\_key\_id\s\?=\s\?\(.*\)$')
            continue
        fi

        if echo "$LINE" | grep --quiet 'aws_secret_access_key'; then
            SECRET_KEY=$(expr "$LINE" : '^aws\_secret\_access\_key\s\?=\s\?\(.*\)$')
            continue
        fi
    done < <(echo "$GREP_OUTPUT")

    echo "$ACCESS_KEY" "$SECRET_KEY"
}

_aws-get-ec2-url-for-profile() {

    if [[ -z "$1" ]]; then
        echo 'No profile informed to search for a region'
        return 1
    fi

    local AWS_CONFIG_FILE="$HOME/.aws/config"

    _aws-file-exists "$AWS_CONFIG_FILE"

    if [[ $? -ne 0 ]]; then
        return 1
    fi

    local AWS_PROFILE_SECTION
    local LINE

    AWS_PROFILE_SECTION=$(awk '/\[.+\]/ {isSection=0}; /\[profile '"$1"'\]/ {isSection=1}; isSection==1 {print}' "$AWS_CONFIG_FILE")

    while read -r LINE; do
        if echo "$LINE" | grep --quiet 'region'; then
            AWS_REGION=$(expr "$LINE" : '^region\s\?=\s\?\(.*\)$')
            continue
        fi
    done < <(echo "$AWS_PROFILE_SECTION")

    echo "$AWS_REGION"

}

_aws-region-exists() {

    if [[ -z "$1" ]]; then
        echo "No region was informed with the command"
        return 1
    fi

    local AWS_REGIONS=$(_aws-get-all-regions)

    if [[ " $AWS_REGIONS " =~ " $1 " ]]; then
        return 0
    else
        echo "The provided region doesn't exist in our list"
        return 1
    fi

}

_aws-get-all-regions() {
    echo 'ap-northeast-1 ap-southeast-1 ap-southeast-2 eu-central-1 eu-west-1 sa-east-1 us-east-1 us-west-1 us-west-2'
}
