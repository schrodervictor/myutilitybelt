MUB_LOG_DIR="$HOME/Logs/zsh"

if ! [ -d "$MUB_LOG_DIR" ]; then
    mkdir -p "$MUB_LOG_DIR"
fi

_mub_logger_get_filename() {
    echo "$MUB_LOG_DIR/$(date +"%Y-%m-%d").log"
}

_mub_ensure_dir() {
    local dirname
    dirname="$1"

    [ -d "$dirname" ] && return 0
    mkdir -p "$dirname"
}

_mub_ensure_file() {
    local filename
    filename="$1"

    [ -f "$filename" ] && return 0

    _mub_ensure_dir "${filename%/*}" && touch "$filename"

    echo "Log file initialized at $(date)" >> "$filename"
    printenv >> "$filename"
}

_mub_log_format() {
    local cmd_str
    cmd_str="$1"

    echo "$(date +'%T')	$PWD	$cmd_str"
}

_mub_logger() {
    local filename
    local cmd_typed
    local cmd_short
    local cmd_full
    local log_line

    cmd_typed="$1"
    cmd_short="$2"
    cmd_full="$3"

    filename="$(_mub_logger_get_filename)"
    _mub_ensure_file "$filename"

    log_line="$(_mub_log_format "$cmd_typed")"
    echo "$log_line" >> "$filename"
}

preexec_functions=(_mub_logger)
