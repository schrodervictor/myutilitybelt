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

function github-request {
    github-validate-env || return 1

    local METHOD='GET'
    local BASE_URL='https://api.github.com'
    local ACCEPT='application/vnd.github.v3+json'

    local ENDPOINT
    local DATA

    while [ $# -gt 0 ]; do
        case "$1" in
            -e|--endpoint)
                ENDPOINT="$2"
                shift 2
                ;;
            -m|--method)
                METHOD="$2"
                shift 2
                ;;
            -d|--data)
                DATA="$2"
                shift 2
                ;;
            --diff)
                ACCEPT='application/vnd.github.v3.diff'
                shift
                ;;
            --json)
                ACCEPT='application/vnd.github.v3+json'
                shift
                ;;
            *)
                echo -e "Invalid option: $1\n"
                return 1
                ;;
        esac
    done

    local CURL_OPTS=()

    CURL_OPTS+=(-X "$METHOD")
    CURL_OPTS+=(-H "Accept: $ACCEPT")
    CURL_OPTS+=(-H "Authorization: token $GITHUB_ACCESS_TOKEN")
    CURL_OPTS+=(-H "User-Agent: $GITHUB_USERNAME")

    if [ -n "$DATA" ]; then
        CURL_OPTS+=(--data-ascii "$DATA")
    fi

    curl -s "${CURL_OPTS[@]}" "$BASE_URL/$ENDPOINT"
}

function github-create-repo {
    github-validate-env || return 1

    local ENDPOINT="user/repos"
    local REPO_NAME
    local REPO_DESCRIPTION
    local REPO_OWNER
    local REPO_PRIVATE

    echo -n "Owner of the repository [$GITHUB_USERNAME]: "
    read REPO_OWNER

    REPO_OWNER="${REPO_OWNER:-$GITHUB_USERNAME}"

    if [[ "$GITHUB_USERNAME" != "$REPO_OWNER" ]]; then
        ENDPOINT="orgs/$REPO_OWNER/repos"
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

    local PAYLOAD=()

    PAYLOAD+=('"name":"'$REPO_NAME'"')
    PAYLOAD+=('"description":"'$REPO_DESCRIPTION'"')

    if [[ " y Y " =~ " ${REPO_PRIVATE} " ]]; then
        PAYLOAD+=('"private":true')
    fi

    local JSON="{$(IFS=,; echo "${PAYLOAD[*]}")}"

    github-request -m POST -e "$ENDPOINT" -d "$JSON"
}

function github-current-repo-name {
    # Check if current directory is a git repo
    git rev-parse > /dev/null 2>&1 || return 1

    local GIT_DIR="$(git rev-parse --git-dir)"
    local PATTERN='^.*url.*=.*git@github.com:\(.\+\).git$'
    local REPO_NAME="$(cat "$GIT_DIR/config" | sed -n "s/$PATTERN/\1/p")"

    if [ -z "$REPO_NAME" ]; then
        return 1
    fi

    echo "$REPO_NAME"
}

function github-create-pull-request {
    github-validate-env || return 1

    local TITLE
    local DEST

    while [ $# -gt 0 ]; do
      case "$1" in
        -m|--message)
          TITLE="$2"
          shift 2
          ;;
        -b|--base)
          BASE="$2"
          shift 2
          ;;
        *)
          echo -e "Invalid option: $1\n"
          return 1
          ;;
      esac
    done

    local HEAD="$(git rev-parse --abbrev-ref HEAD)"
    local REPO="$(github-current-repo-name)"
    local REPO_OWNER="${REPO%/*}"
    local REPO_NAME="${REPO#*/}"

    BASE="${BASE:-master}"
    TITLE="${TITLE:-"$HEAD into $BASE"}"

    if [[ $HEAD = $BASE ]]; then
        echo 'HEAD and merge base must be different.'
        echo "[$HEAD] given for both."
        return 1
    fi

    local ENDPOINT="repos/$REPO_OWNER/$REPO_NAME/pulls"

    local PAYLOAD=()

    PAYLOAD+=('"title":"'$TITLE'"')
    PAYLOAD+=('"head":"'$HEAD'"')
    PAYLOAD+=('"base":"'$BASE'"')

    local JSON="{$(IFS=,; echo "${PAYLOAD[*]}")}"

    github-request -m POST -e "$ENDPOINT" -d "$JSON"
}

function github-view-pull-request {
    github-validate-env || return 1

    local REPO="$(github-current-repo-name)"
    local REPO_OWNER="${REPO%/*}"
    local REPO_NAME="${REPO#*/}"
    local PR_NUMBER="$1"

    local ENDPOINT="repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER"

    local DIFF="$(github-request -e "$ENDPOINT" --diff)"

    echo "$DIFF" | vim -
}

function github-list-repos {
    github-validate-env || return 1
    github-request -e 'user/repos'
}
