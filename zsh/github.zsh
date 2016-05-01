# ~/.zshrc
#
# @package myutilitybelt
# @subpackage zsh
# @author Victor Schröder <schrodervictor@gmail.com>

function github-create-repo {

    if [[ -z "$GITHUB_ACCESS_TOKEN" ]]; then
        echo 'Your GitHub access token is not correctly configured'
        echo 'Make sure you have GITHUB_ACCESS_TOKEN in your environment'
        return 1
    fi

    local REPO_NAME
    local REPO_DESCRIPTION
    echo $REPO_NAME $REPO_DESCRIPTION

    echo -n "Enter the repository name: "
    read REPO_NAME

    echo -n "Enter the repository description: "
    read REPO_DESCRIPTION

    curl -H 'Accept: application/vnd.github.v3+json' \
        -H "Authorization: token $GITHUB_ACCESS_TOKEN" \
        -H 'User-Agent: schrodervictor' \
        -X POST -i https://api.github.com/user/repos \
        --data-ascii "{\"name\": \"$REPO_NAME\", \"description\": \"$REPO_DESCRIPTION\"}"
}
