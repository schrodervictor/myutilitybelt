# ~/.zshrc
#
# @package myutilitybelt
# @subpackage zsh
# @author Victor Schröder <schrodervictor@gmail.com>

function github-validate-env {

    local VALID_ENV=true

    if [[ -z "$GITHUB_USERNAME" ]]; then
        echo 'ERROR: Your GitHub username is not correctly configured'
        echo 'Make sure you have GITHUB_USERNAME in your environment'
        unset VALID_ENV
    fi

    if [[ -z "$GITHUB_ACCESS_TOKEN" ]]; then
        echo 'ERROR: Your GitHub access token is not correctly configured'
        echo 'Make sure you have GITHUB_ACCESS_TOKEN in your environment'
        unset VALID_ENV
    fi

    if [[ -z "$VALID_ENV" ]]; then
        return 1
    fi
}

function github-create-repo {

    github-validate-env || return 1

    local GITHUB_ENDPOINT="https://api.github.com/user/repos"
    local REPO_NAME
    local REPO_DESCRIPTION
    local REPO_OWNER
    local REPO_PRIVATE
    local PARAMS=()

    echo -n "Owner of the repository [$GITHUB_USERNAME]: "
    read REPO_OWNER

    REPO_OWNER="${REPO_OWNER:-$GITHUB_USERNAME}"

    if [[ "$GITHUB_USERNAME" != "$REPO_OWNER" ]]; then
        GITHUB_ENDPOINT="https://api.github.com/orgs/$REPO_OWNER/repos"
    fi

    echo -n "Private? (Y/n): "
    read REPO_PRIVATE

    REPO_PRIVATE="${REPO_PRIVATE:-y}"

    if [[ ! " y n Y N " =~ " $REPO_PRIVATE " ]]; then
        echo "Invalid option"
        return 1
    fi

    echo -n "Enter the repository name: "
    read REPO_NAME

    if [[ -z "$REPO_NAME" ]]; then
        echo 'You have to give the repo a name. Try again...'
        return 1
    fi

    echo -n "Enter the repository description: "
    read REPO_DESCRIPTION

    PARAMS+=('"name":"'$REPO_NAME'"')
    PARAMS+=('"description":"'$REPO_DESCRIPTION'"')

    if [[ " y Y " =~ " ${REPO_PRIVATE} " ]]; then
        PARAMS+=('"private":true')
    fi

    curl \
        -X POST \
        -i "$GITHUB_ENDPOINT" \
        -H 'Accept: application/vnd.github.v3+json' \
        -H "Authorization: token $GITHUB_ACCESS_TOKEN" \
        -H "User-Agent: $GITHUB_USERNAME" \
        --data-ascii "{$(IFS=,; echo "${PARAMS[*]}")}"
}
