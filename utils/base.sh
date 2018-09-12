#!/usr/bin/env bash
# base.sh

# Functions ###########################################

function is_retropie() {
    [[ -d "$RP_DIR" && -d "$home/.emulationstation" && -d "/opt/retropie" ]]
}

function restart_ES() {
    local restart_file="/tmp/es-restart"
    touch "$restart_file"
    chown -R "$user":"$user" "$restart_file"
    kill $(pidof emulationstation)
}


function log() {
    if [[ "$GUI_FLAG" -eq 1 ]]; then
        echo "$*" >> "$LOG_FILE"
    fi
    echo "$*"
}


function check_argument() {
    # This method doesn't accept arguments starting with '-'.
    if [[ -z "$2" || "$2" =~ ^- ]]; then
        echo >&2
        echo "ERROR: '$1' is missing an argument." >&2
        echo >&2
        echo "Try '$0 --help' for more info." >&2
        echo >&2
        return 1
    fi
}


function usage() {
    echo
    underline "$SCRIPT_TITLE"
    echo "$SCRIPT_DESCRIPTION"
    echo
    echo "USAGE: $0 [OPTIONS]"
    echo
    echo "Use '$0 --help' to see all the options."
}


function underline() {
    if [[ -z "$1" ]]; then
        echo "ERROR: '$FUNCNAME' needs a message as an argument!" >&2
        exit 1
    fi
    local dashes
    local message="$1"
    [[ "$GUI_FLAG" -eq 1 ]] && log "$message" || echo "$message"
    for ((i=1; i<="${#message}"; i+=1)); do [[ -n "$dashes" ]] && dashes+="-" || dashes="-"; done
    [[ "$GUI_FLAG" -eq 1 ]] && log "$dashes" || echo "$dashes"
}