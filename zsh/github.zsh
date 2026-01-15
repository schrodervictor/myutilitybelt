# ~/.zshrc
#
# @package myutilitybelt
# @subpackage zsh
# @author Victor Schröder <schrodervictor@gmail.com>

function github-validate-env {
    local valid_env=true

    if [[ -z "$GITHUB_USERNAME" ]]; then
        echo 'ERROR: Your GitHub username is not correctly configured'
        echo 'Make sure you have GITHUB_USERNAME in your environment'
        unset valid_env
    fi

    if [[ -z "$GITHUB_ACCESS_TOKEN" ]]; then
        echo 'ERROR: Your GitHub access token is not correctly configured'
        echo 'Make sure you have GITHUB_ACCESS_TOKEN in your environment'
        unset valid_env
    fi

    if [[ -z "$valid_env" ]]; then
        return 1
    fi
}

function github-validate-dir {
    local quiet=
    if [[ "$1" = "-q" ]]; then
        quiet=true
    fi

    git rev-parse > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        $quiet echo 'Current directory is not in a git repository'
        return 1
    fi

    local git_dir="$(git rev-parse --git-dir)/config"

    cat "$git_dir" | grep -q 'url.*=.*git@github\.com:.*\.git'

    if [ $? -ne 0 ]; then
        $quiet echo 'Current repository does not have Github as a remote'
        return 1
    fi

    return 0
}

function github-request {
    github-validate-env || return 1

    local method='GET'
    local base_url='https://api.github.com'
    local accept='application/vnd.github.v3+json'
    local verbose=false

    local endpoint
    local data

    while [ $# -gt 0 ]; do
        case "$1" in
            -e|--endpoint)
                endpoint="$2"
                shift 2
                ;;
            -m|--method)
                method="$2"
                shift 2
                ;;
            -d|--data)
                data="$2"
                shift 2
                ;;
            --diff)
                accept='application/vnd.github.v3.diff'
                shift
                ;;
            --json)
                accept='application/vnd.github.v3+json'
                shift
                ;;
            --beta)
                accept='application/vnd.github.squirrel-girl-preview+json'
                shift
                ;;
            --accept)
                accept="$2"
                shift 2
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            *)
                echo -e "Invalid option: $1\n"
                return 1
                ;;
        esac
    done

    local curl_opts=()

    curl_opts+=(--request "$method")
    curl_opts+=(--header "Accept: $accept")
    curl_opts+=(--header "User-Agent: $GITHUB_USERNAME")
    curl_opts+=(--header "Authorization: Bearer $GITHUB_ACCESS_TOKEN")
    curl_opts+=(--header "X-GitHub-Api-Version: 2022-11-28")

    if [ -n "$data" ]; then
        curl_opts+=(--data-ascii "$data")
    fi

    if [ "$verbose" = true ]; then
        curl_opts+=(--verbose)
    fi

    echo curl -s "${curl_opts[@]}" "$base_url/$endpoint" >&2
    curl -v -s "${curl_opts[@]}" "$base_url/$endpoint"
}

function github-create-repo {
    github-validate-env || return 1

    local endpoint="user/repos"

    local repo_owner
    echo -n "Owner of the repository [$GITHUB_USERNAME]: "
    read repo_owner

    repo_owner="${repo_owner:-$GITHUB_USERNAME}"

    if [[ "$GITHUB_USERNAME" != "$repo_owner" ]]; then
        endpoint="orgs/$repo_owner/repos"
    fi

    local repo_private
    echo -n "Private? (Y/n): "
    read repo_private

    repo_private="${repo_private:-y}"

    if [[ ! " y n Y N " =~ " $repo_private " ]]; then
        echo "Invalid option"
        return 1
    fi

    local repo_name
    echo -n "Enter the repository name: "
    read repo_name

    if [[ -z "$repo_name" ]]; then
        echo 'You have to give the repo a name. Try again...'
        return 1
    fi

    local repo_description
    echo -n "Enter the repository description: "
    read repo_description

    local payload=()

    payload+=('"name":"'$repo_name'"')
    payload+=('"description":"'$repo_description'"')

    if [[ " y Y " =~ " ${repo_private} " ]]; then
        payload+=('"private":true')
    fi

    local json="{$(IFS=,; echo "${payload[*]}")}"

    github-request -m POST -e "$endpoint" -d "$json"
}

function github-current-repo-name {
    github-validate-dir || return 1

    local git_dir="$(git rev-parse --git-dir)"
    local pattern='^.*url.*=.*git@github.com:\(.\+\).git$'
    local repo_name="$(cat "$git_dir/config" | sed -n "s/$pattern/\1/p")"

    if [ -z "$repo_name" ]; then
        return 1
    fi

    echo "$repo_name"
}

function github-create-pull-request {
    github-validate-env || return 1
    github-validate-dir || return 1

    local title
    local base

    while [ $# -gt 0 ]; do
      case "$1" in
        -m|--message)
          title="$2"
          shift 2
          ;;
        -b|--base)
          base="$2"
          shift 2
          ;;
        *)
          echo -e "Invalid option: $1\n"
          return 1
          ;;
      esac
    done

    local head="$(git rev-parse --abbrev-ref HEAD)"
    local repo="$(github-current-repo-name)"
    local repo_owner="${repo%/*}"
    local repo_name="${repo#*/}"

    base="${base:-master}"
    title="${title:-"$head into $base"}"

    if [[ $head = $BASE ]]; then
        echo 'HEAD and merge base must be different.'
        echo "[$head] given for both."
        return 1
    fi

    local endpoint="repos/$repo_owner/$repo_name/pulls"

    local payload=()

    payload+=('"title":"'$title'"')
    payload+=('"head":"'$head'"')
    payload+=('"base":"'$base'"')

    local json="{$(IFS=,; echo "${payload[@]}")}"

    github-request -m POST -e "$endpoint" -d "$json"
}

function github-create-issue {
    github-validate-env || return 1
    github-validate-dir || return 1

    local title
    local description

    while [ $# -gt 0 ]; do
      case "$1" in
        -m|--message)
          title="$2"
          shift 2
          ;;
        -d|--description)
          description="$2"
          shift 2
          ;;
        *)
          echo -e "Invalid option: $1\n"
          return 1
          ;;
      esac
    done

    local repo="$(github-current-repo-name)"
    local repo_owner="${repo%/*}"
    local repo_name="${repo#*/}"

    local endpoint="repos/$repo_owner/$repo_name/issues"

    local payload=()
    payload+=("\"title\":\"$title\"")

    if [ -n "$description" ]; then
        payload+=("\"body\":\"$description\"")
    fi

    local json="{$(IFS=,; echo "${payload[*]}")}"

    local result
    result="$(github-request -m POST -e "$endpoint" -d "$json")"

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

    local repo="$(github-current-repo-name)"
    local repo_owner="${repo%/*}"
    local repo_name="${repo#*/}"
    local pr_number="$1"

    if [ -z "$pr_number" ]; then
        echo 'Please provide a valid pull request number'
        return 1
    fi

    local endpoint="repos/$repo_owner/$repo_name/pulls/$pr_number"

    local diff="$(github-request -e "$endpoint" --diff)"

    if [ -z "$diff" ]; then
        echo "Couldn't find any diff for the pull request $pr_number"
        return 1
    fi

    echo -E "$diff"
}

function github-view-pull-request {
    github-pull-request-diff "$@" \
    | vim -c "let g:github_pull_request=$pr_number" -
}

function github-get-all-diffs {
    local repo="$1"
    local line
    local pr_numbers="$(
        while IFS="" read -r line || [ -n "$line" ]; do
            echo "$line" \
            | grep -o '"number":[^,]\+,' \
            | sed -n 's/^"number":\(.\+\),$/\1/p'
        done < "$repo/pulls"
    )"

    local n
    for n in $(echo "$pr_numbers"); do
        (
            echo "Entering $repo"
            cd "$repo"
            echo "Getting diff for pull-request $n"
            mkdir -p "pull-requests/$n"
            github-pull-request-diff "$n" > "pull-requests/$n/diff"
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

    local repo="$(github-current-repo-name)"
    local repo_owner="${repo%/*}"
    local repo_name="${repo#*/}"
    local endpoint="repos/$repo_owner/$repo_name/pulls?state=all&per_page=100"
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

function github-list-pull-requests {
    github-validate-env || return 1
    github-validate-dir || return 1

    local state="open"

    while [ $# -gt 0 ]; do
      case "$1" in
        --closed)
          state="closed"
          shift
          ;;
        --all)
          state="all"
          shift
          ;;
        --open)
          state="open"
          shift
          ;;
        *)
          echo -e "Invalid option: $1\n"
          return 1
          ;;
      esac
    done

    local repo="$(github-current-repo-name)"
    local repo_owner="${repo%/*}"
    local repo_name="${repo#*/}"
    local endpoint="repos/$repo_owner/$repo_name/pulls?state=$state&per_page=100"

    local result="$(github-request -e "$endpoint")"

    local numbers="$(echo "$result" \
        | grep -o '"number":[^,]\+,' \
        | sed -n 's/^"number":\(.\+\),$/\1/p')"

    local titles="$(echo "$result" \
        | grep -o '"title":"[^"]\+"' \
        | sed -n 's/^"title":"\(.\+\)"$/\1/p')"


    local number
    local title

    while read -u 3 -r number && read -u 4 -r title; do
        echo "$number: $title"
    done 3< <(echo "$numbers") 4< <(echo "$titles")
}

function github-list-pull-request-comments {
    github-validate-env || return 1
    github-validate-dir || return 1

    local repo="$(github-current-repo-name)"
    local repo_owner="${repo%/*}"
    local repo_name="${repo#*/}"
    local pr_number="$1"

    local endpoint="repos/$repo_owner/$repo_name/pulls/$pr_number/comments"

    local result="$(github-request -e "$endpoint")"

    local paths="$(echo "$result" \
        | grep -o '"path":"[^"]\+"' \
        | sed -n 's/^"path":"\(.\+\)"$/\1/p')"

    local hunks="$(echo "$result" \
        | grep -o '"diff_hunk":"@@[^@]\+@@' \
        | sed -n 's/^"diff_hunk":"\(.\+\)$/\1/p')"

    local positions="$(echo "$result" \
        | grep -o '"position":[^,]\+,' \
        | sed -n 's/^"position":\(.\+\),$/\1/p')"

    local dates="$(echo "$result" \
        | grep -o '"created_at":"[^"]\+"' \
        | sed -n 's/^"created_at":"\(.\+\)"$/\1/p')"

    local authors="$(echo "$result" \
        | grep -o '"login":"[^"]\+"' \
        | sed -n 's/^"login":"\(.\+\)"$/\1/p')"

    # Comments normally have tons of escaped chars. We have to take that in
    # consideration and prevent bash to expand the line breaks, for example
    local comments="$(echo "${result//\\/\\\\}" \
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
        3< <(echo "$paths") \
        4< <(echo "$hunks") \
        5< <(echo "$positions") \
        6< <(echo "$dates") \
        7< <(echo "$authors") \
        8< <(echo "${comments//\\/\\\\}")
}

function _github-view-pull-request {
    github-validate-dir -q || return 1

    local pr_list="$(github-list-pull-requests)"

    # Zsh completion
    if command -v _describe > /dev/null 2>&1; then
        local -a options
        local option

        while read -r option; do
            options+=( "$option" )
        done < <(echo "$pr_list")

        _describe 'github-view-pull-request' options

        return 0
    fi

    # Bash completion
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local orig_ifs="$IFS"
    local IFS=$'\n'

    COMPREPLY=( $(compgen -W "$pr_list" -- "$CUR") )
    IFS="$orig_ifs"

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
