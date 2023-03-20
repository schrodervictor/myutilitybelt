debug() {
    [ "$DEBUG" = true ] && echo "DEBUG: $@" >&2
}

get_my_ip() {
    curl -s ip.me
}

is_function() {
    local exists
    declare -f -F "$1" > /dev/null;
    exists="$?"
    debug "is_function $1: $exists"
    return $exists
}

atlas() {
    local function_name
    local subcmd

    if [ -z "$1" ]; then
        _atlas_help
        return 1
    fi

    subcmd="$1"
    shift

    debug "atlas args $@"
    debug "atlas subcmd $subcmd"

    function_name="_atlas_${subcmd}"

    if ! is_function "$function_name"; then
        echo "Not recognized subcommand $subcmd"
        _atlas_help
        return 1
    fi

    "$function_name" "$@"
}

_atlas_to_iso_date() {
    local value="$1"

    case "$value" in
        EOD)
            echo "$(date --iso-8601 --date '+1 day')"'T23:59:59+01:00'
            ;;
        *)
            echo "$value"
            ;;
    esac
}

_atlas_echo() {
    echo "Hello from Atlas Echo!"
}

_atlas_help() {
    echo "Hello from Atlas Help!"
}

_atlas_whitelist() {
    local ip
    local comment
    local project

    while [ $# -gt 0 ]; do
        case "$1" in
            --ip)
                ip="$2"
                shift 2
                ;;
            --project)
                project="$2"
                shift 2
                ;;
            --comment)
                comment="$2"
                shift 2
                ;;
            --delete-after)
                delete_after="$2"
                shift 2
                ;;
            *)
                echo -e "Invalid option: $1\n"
                return 1
                ;;
        esac
    done

    if [ -z "$project" ]; then
        echo "atlas whitelist: --project is mandatory"
        return 1
    fi

    if [ -z "$ip" ]; then
        ip="$(get_my_ip)"
    fi

    if [ -z "$comment" ]; then
        comment="Victor Schroeder"
    fi

    if [ -z "$delete_after" ]; then
        delete_after='EOD'
    fi

    delete_after="$(_atlas_to_iso_date "$delete_after")"

    local payload=()

    payload+=('"ipAddress":"'"$ip"'"')
    payload+=('"comment":"'"$comment"'"')

    if [ -n "$delete_after" ]; then
        payload+=('"deleteAfterDate":"'"$delete_after"'"')
    fi

    local json="[{$(IFS=,; echo "${payload[*]}")}]"

    local request_args=()
    request_args+=(--method POST)
    request_args+=(--endpoint "groups/$project/whitelist")
    request_args+=(--data "$json")

    local result
    result="$(_atlas_request "${request_args[@]}")"

    if [ "$?" -eq 0 ]; then
        echo "Successfully added $ip to $project whitelist"
    else
        echo "Failed to add $ip to $project whitelist"
        echo "$result"
        return 1
    fi
}

_atlas_validate_env() {
    local valid_env=true

    if [ -z "$MONGODB_ATLAS_PUBLIC_KEY" ]; then
        echo 'ERROR: MongoDB Atlas public key not correctly configured'
        echo 'Make sure to set MONGODB_ATLAS_PUBLIC_KEY in your environment'
        unset valid_env
    fi

    if [ -z "$MONGODB_ATLAS_PRIVATE_KEY" ]; then
        echo 'ERROR: MongoDB Atlas private key not correctly configured'
        echo 'Make sure to set MONGODB_ATLAS_PRIVATE_KEY in your environment'
        unset valid_env
    fi

    if [ -z "$valid_env" ]; then
        return 1
    fi
}

_atlas_curl() {
    local output_file
    local http_code

    output_file="$(mktemp)"
    http_code="$(curl --output "$output_file" --write-out '%{http_code}' "$@")"

    debug "[curl] status code: $http_code"
    debug "[curl] raw response: $(cat "$output_file")"

    cat "$output_file"
    rm "$output_file"
    if [ $http_code -lt 200 ] || [ $http_code -gt 299 ]; then
        return 1
    fi
}

_atlas_request() {
    _atlas_validate_env || return 1

    local method='GET'
    local base_url='https://cloud.mongodb.com/api/atlas/v1.0'

    local endpoint
    local data

    while [ $# -gt 0 ]; do
        case "$1" in
            --endpoint)
                endpoint="$2"
                shift 2
                ;;
            --method)
                method="$2"
                shift 2
                ;;
            --data)
                data="$2"
                shift 2
                ;;
            *)
                echo -e "Invalid option: $1\n"
                return 1
                ;;
        esac
    done

    local curl_opts=()

    curl_opts+=(--request "$method")
    curl_opts+=(--user "$MONGODB_ATLAS_PUBLIC_KEY:$MONGODB_ATLAS_PRIVATE_KEY")
    curl_opts+=(--digest)
    curl_opts+=(--header 'Content-Type: application/json')
    curl_opts+=(--header 'Accept: application/json')

    if [ -n "$data" ]; then
        curl_opts+=(--data-ascii "$data")
    fi

    debug "[_atlas_request] curl URL: $base_url/$endpoint"
    debug "[_atlas_request] curl args: ${curl_opts[@]}"

    local response
    local cmd_return

    response="$(_atlas_curl --silent "${curl_opts[@]}" "$base_url/$endpoint")"
    cmd_return="$?"

    echo "$response"
    return "$cmd_return"
}
