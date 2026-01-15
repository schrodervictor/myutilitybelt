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

function github-validate-dir {
    local QUIET=
    if [[ "$1" = "-q" ]]; then
        QUIET=true
    fi

    git rev-parse > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        $QUIET echo 'Current directory is not in a git repository'
        return 1
    fi

    local GIT_DIR="$(git rev-parse --git-dir)/config"

    cat "$GIT_DIR" | grep -q 'url.*=.*git@github\.com:.*\.git'

    if [ $? -ne 0 ]; then
        $QUIET echo 'Current repository does not have Github as a remote'
        return 1
    fi

    return 0
}

function github-request {
    github-validate-env || return 1

    local METHOD='GET'
    local BASE_URL='https://api.github.com'
    local ACCEPT='application/vnd.github.v3+json'
    local VERBOSE=false

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
            --beta)
                ACCEPT='application/vnd.github.squirrel-girl-preview+json'
                shift
                ;;
            --accept)
                ACCEPT="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=true
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

    if [ "$VERBOSE" = true ]; then
        CURL_OPTS+=(--verbose)
    fi

    echo curl -s "${CURL_OPTS[@]}" "$BASE_URL/$ENDPOINT" >&2
    curl -v -s "${CURL_OPTS[@]}" "$BASE_URL/$ENDPOINT"
}

function github-create-repo {
    github-validate-env || return 1

    local ENDPOINT="user/repos"

    local REPO_OWNER
    echo -n "Owner of the repository [$GITHUB_USERNAME]: "
    read REPO_OWNER

    REPO_OWNER="${REPO_OWNER:-$GITHUB_USERNAME}"

    if [[ "$GITHUB_USERNAME" != "$REPO_OWNER" ]]; then
        ENDPOINT="orgs/$REPO_OWNER/repos"
    fi

    local REPO_PRIVATE
    echo -n "Private? (Y/n): "
    read REPO_PRIVATE

    REPO_PRIVATE="${REPO_PRIVATE:-y}"

    if [[ ! " y n Y N " =~ " $REPO_PRIVATE " ]]; then
        echo "Invalid option"
        return 1
    fi

    local REPO_NAME
    echo -n "Enter the repository name: "
    read REPO_NAME

    if [[ -z "$REPO_NAME" ]]; then
        echo 'You have to give the repo a name. Try again...'
        return 1
    fi

    local REPO_DESCRIPTION
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
    github-validate-dir || return 1

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
    github-validate-dir || return 1

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

    local JSON="{$(IFS=,; echo "${PAYLOAD[@]}")}"

    github-request -m POST -e "$ENDPOINT" -d "$JSON"
}

function github-create-issue {
    github-validate-env || return 1
    github-validate-dir || return 1

    local TITLE
    local DESCRIPTION

    while [ $# -gt 0 ]; do
      case "$1" in
        -m|--message)
          TITLE="$2"
          shift 2
          ;;
        -d|--description)
          DESCRIPTION="$2"
          shift 2
          ;;
        *)
          echo -e "Invalid option: $1\n"
          return 1
          ;;
      esac
    done

    local REPO="$(github-current-repo-name)"
    local REPO_OWNER="${REPO%/*}"
    local REPO_NAME="${REPO#*/}"

    local ENDPOINT="repos/$REPO_OWNER/$REPO_NAME/issues"

    local PAYLOAD=()
    PAYLOAD+=("\"title\":\"$TITLE\"")

    if [ -n "$DESCRIPTION" ]; then
        PAYLOAD+=("\"body\":\"$DESCRIPTION\"")
    fi

    local JSON="{$(IFS=,; echo "${PAYLOAD[*]}")}"

    local result
    result="$(github-request -m POST -e "$ENDPOINT" -d "$JSON")"

    local issue_id
    issue_id="$(echo "$result" \
        | sed -n 's|^{.*"id": *\([[:digit:]]\+\) *\(,.\+\)\?}$|\1|p')"

    local issue_number
    issue_number="$(echo "$result" \
        | sed -n 's|^{.*"number": *\([[:digit:]]\+\) *\(,.\+\)\?}$|\1|p')"

    local issue_url
    issue_url="$(echo "$result" \
        | sed -n 's|^{.*"html_url" *: *"\([^"]\+/issues/[^"]\+\)" *\(,.\+\)\?}$|\1|p')"

    if [ -z "$issue_id" -o -z "$issue_url" -o -z "$issue_number" ]; then
        echo 'Failed to create issue on Github'
        echo 'Returned JSON:'
        echo "$result"
        return 1
    fi

    echo "Successfully created new issue #${issue_number}"
    echo "id: $issue_id"
    echo "url: $issue_url"
}

function github-pull-request-diff {
    github-validate-env || return 1
    github-validate-dir || return 1

    local REPO="$(github-current-repo-name)"
    local REPO_OWNER="${REPO%/*}"
    local REPO_NAME="${REPO#*/}"
    local PR_NUMBER="$1"

    if [ -z "$PR_NUMBER" ]; then
        echo 'Please provide a valid pull request number'
        return 1
    fi

    local ENDPOINT="repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER"

    local DIFF="$(github-request -e "$ENDPOINT" --diff)"

    if [ -z "$DIFF" ]; then
        echo "Couldn't find any diff for the pull request $PR_NUMBER"
        return 1
    fi

    echo -E "$DIFF"
}

function github-view-pull-request {
    github-pull-request-diff "$@" \
    | vim -c "let g:github_pull_request=$PR_NUMBER" -
}

function github-get-all-diffs {
    local REPO="$1"
    local LINE
    local PR_NUMBERS="$(
        while IFS="" read -r LINE || [ -n "$LINE" ]; do
            echo "$LINE" \
            | grep -o '"number":[^,]\+,' \
            | sed -n 's/^"number":\(.\+\),$/\1/p'
        done < "$REPO/pulls"
    )"

    local N
    for N in $(echo "$PR_NUMBERS"); do
        (
            echo "Entering $REPO"
            cd "$REPO"
            echo "Getting diff for pull-request $N"
            mkdir -p "pull-requests/$N"
            github-pull-request-diff "$N" > "pull-requests/$N/diff"
        )
    done
}

function github-list-repos {
    github-validate-env || return 1

    local endpoint="user/repos?per_page=100"
    local page=1

    local result
    while ! [ "$result" = '[]' ]; do
        if [ "$page" -gt 10 ]; then
            break
        fi
        result="$(github-request -e "${endpoint}&page=$page")"
        echo -E "$result"
        ((page++))
    done
}

function github-get-all-pull-requests {
    github-validate-env || return 1
    github-validate-dir || return 1

    local REPO="$(github-current-repo-name)"
    local REPO_OWNER="${REPO%/*}"
    local REPO_NAME="${REPO#*/}"
    local ENDPOINT="repos/$REPO_OWNER/$REPO_NAME/pulls?state=all&per_page=100"
    local PAGE=1

    local RESULT
    while ! [ "$RESULT" = '[]' ]; do
        if [ "$PAGE" -gt 10 ]; then
            break
        fi
        RESULT="$(github-request -e "${ENDPOINT}&page=$PAGE")"
        echo -E "$RESULT"
        ((PAGE++))
    done
}

function github-list-pull-requests {
    github-validate-env || return 1
    github-validate-dir || return 1

    local STATE="open"

    while [ $# -gt 0 ]; do
      case "$1" in
        --closed)
          STATE="closed"
          shift
          ;;
        --all)
          STATE="all"
          shift
          ;;
        --open)
          STATE="open"
          shift
          ;;
        *)
          echo -e "Invalid option: $1\n"
          return 1
          ;;
      esac
    done

    local REPO="$(github-current-repo-name)"
    local REPO_OWNER="${REPO%/*}"
    local REPO_NAME="${REPO#*/}"
    local ENDPOINT="repos/$REPO_OWNER/$REPO_NAME/pulls?state=$STATE&per_page=100"

    local RESULT="$(github-request -e "$ENDPOINT")"

    local NUMBERS="$(echo "$RESULT" \
        | grep -o '"number":[^,]\+,' \
        | sed -n 's/^"number":\(.\+\),$/\1/p')"

    local TITLES="$(echo "$RESULT" \
        | grep -o '"title":"[^"]\+"' \
        | sed -n 's/^"title":"\(.\+\)"$/\1/p')"


    local NUMBER
    local TITLE

    while read -u 3 -r NUMBER && read -u 4 -r TITLE; do
        echo "$NUMBER: $TITLE"
    done 3< <(echo "$NUMBERS") 4< <(echo "$TITLES")
}

function github-list-pull-request-comments {
    github-validate-env || return 1
    github-validate-dir || return 1

    local REPO="$(github-current-repo-name)"
    local REPO_OWNER="${REPO%/*}"
    local REPO_NAME="${REPO#*/}"
    local PR_NUMBER="$1"

    local ENDPOINT="repos/$REPO_OWNER/$REPO_NAME/pulls/$PR_NUMBER/comments"

    local RESULT="$(github-request -e "$ENDPOINT")"

    local PATHS="$(echo "$RESULT" \
        | grep -o '"path":"[^"]\+"' \
        | sed -n 's/^"path":"\(.\+\)"$/\1/p')"

    local HUNKS="$(echo "$RESULT" \
        | grep -o '"diff_hunk":"@@[^@]\+@@' \
        | sed -n 's/^"diff_hunk":"\(.\+\)$/\1/p')"

    local POSITIONS="$(echo "$RESULT" \
        | grep -o '"position":[^,]\+,' \
        | sed -n 's/^"position":\(.\+\),$/\1/p')"

    local DATES="$(echo "$RESULT" \
        | grep -o '"created_at":"[^"]\+"' \
        | sed -n 's/^"created_at":"\(.\+\)"$/\1/p')"

    local AUTHORS="$(echo "$RESULT" \
        | grep -o '"login":"[^"]\+"' \
        | sed -n 's/^"login":"\(.\+\)"$/\1/p')"

    # Comments normally have tons of escaped chars. We have to take that in
    # consideration and prevent bash to expand the line breaks, for example
    local COMMENTS="$(echo "${RESULT//\\/\\\\}" \
        | grep -o '"body":"\(\\.\|[^"]\)\+"' \
        | sed -n 's/^"body":"\(.\+\)"$/\1/p')"

    while \
        read -u 3 -r _PATH \
        && read -u 4 -r _HUNK \
        && read -u 5 -r _POSITION \
        && read -u 6 -r _DATE \
        && read -u 7 -r _AUTHOR \
        && read -u 8 -r _COMMENT
    do
        # If position is null, this is an outdated comment
        if [ "$_POSITION" = 'null' ]; then
            continue
        fi

        echo "$_PATH"
        echo "$_HUNK"
        echo "$_POSITION"
        echo "$_DATE"
        echo "$_AUTHOR"
        echo "${_COMMENT//\\/\\\\}"
        echo
    done \
        3< <(echo "$PATHS") \
        4< <(echo "$HUNKS") \
        5< <(echo "$POSITIONS") \
        6< <(echo "$DATES") \
        7< <(echo "$AUTHORS") \
        8< <(echo "${COMMENTS//\\/\\\\}")
}

function _github-view-pull-request {
    github-validate-dir -q || return 1

    local PR_LIST="$(github-list-pull-requests)"

    # Zsh completion
    if command -v _describe > /dev/null 2>&1; then
        local -a OPTIONS
        local OPTION

        while read -r OPTION; do
            OPTIONS+=( "$OPTION" )
        done < <(echo "$PR_LIST")

        _describe 'github-view-pull-request' OPTIONS

        return 0
    fi

    # Bash completion
    local CUR="${COMP_WORDS[COMP_CWORD]}"
    local ORIG_IFS="$IFS"
    local IFS=$'\n'

    COMPREPLY=( $(compgen -W "$PR_LIST" -- "$CUR") )
    IFS="$ORIG_IFS"

    if [[ ${#COMPREPLY[*]} -eq 1 ]]; then
        COMPREPLY=( ${COMPREPLY[0]%%: *} )
    fi

    return 0
}

if command -v complete > /dev/null 2>&1; then
    complete -F _github-view-pull-request github-view-pull-request
    complete -F _github-view-pull-request github-list-pull-request-comments
fi

if command -v compdef  > /dev/null 2>&1; then
    compdef _github-view-pull-request github-view-pull-request
    compdef _github-view-pull-request github-list-pull-request-comments
fi
