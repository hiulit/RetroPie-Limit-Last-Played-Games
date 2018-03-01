#!/usr/bin/env bash
# retropie_limit_last_played_games.sh
#
# Retropie Limit Last Played Games
# A tool for RetroPie to limit the number of 'last played' games.
#
# Author: hiulit
# Repository: https://github.com/hiulit/RetroPie-Limit-Last-Played-Games
# License: https://github.com/hiulit/RetroPie-Limit-Last-Played-Games/blob/master/LICENSE 
#
# Requirements:
# - RetroPie 4.x.x


# Globals ########################################

user="$SUDO_USER"
[[ -z "$user" ]] && user="$(id -un)"

home="$(eval echo ~$user)"

readonly RP_DIR="$home/RetroPie"
readonly RP_ROMS_DIR="$RP_DIR/roms"
readonly RP_CONFIGS_DIR="/opt/retropie/configs"
readonly ES_GAMELISTS_DIR="$RP_CONFIGS_DIR/all/emulationstation/gamelists"

readonly SCRIPT_VERSION="0.0.1"
readonly SCRIPT_DIR="$(cd "$(dirname $0)" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_FULL="$SCRIPT_DIR/SCRIPT_NAME"
readonly SCRIPT_TITLE="Retropie Limit Last Played Games"
readonly SCRIPT_DESCRIPTION="A tool for RetroPie to limit the number of 'last played' games."


# Variables #######################################

# Add as many systems as needed.
SYSTEMS=()

# Number of games to limit per system (10 by default).
nth_last_played=10


# Functions ######################################

function is_retropie() {
    [[ -d "$RP_DIR" && -d "$home/.emulationstation" && -d "/opt/retropie" ]]
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
    echo "$message"
    for ((i=1; i<="${#message}"; i+=1)); do [[ -n "$dashes" ]] && dashes+="-" || dashes="-"; done && echo "$dashes"
}


function find_gamelist_xml() {
    if [[ ! -f "$RP_ROMS_DIR/$system/gamelist.xml" ]]; then
        echo "ERROR: '$RP_ROMS_DIR/$system/gamelist.xml' doesn't exist!" >&2
        echo "> Trying '$ES_GAMELISTS_DIR/$system/gamelist.xml' ..."
        if [[ ! -f "$ES_GAMELISTS_DIR/$system/gamelist.xml" ]]; then
            echo "ERROR: '$ES_GAMELISTS_DIR/$system/gamelist.xml' doesn't exist!" >&2
            echo "ERROR: Couldn't find any 'gamelist.xml' for '$system'." >&2
            pos="$((${#SYSTEMS[@]} - 1))"
            last="${SYSTEMS[$pos]}"
            [[ "$system" != "$last" ]] && echo "> Continuing with the next system ..."
            continue
        else
            gamelist_path="$ES_GAMELISTS_DIR/$system/gamelist.xml"
            echo "'gamelist.xml' for '$system' found!"
        fi
    else
        gamelist_path="$RP_ROMS_DIR/$system/gamelist.xml"
        echo "'gamelist.xml' for '$system' found!"
    fi
}


function create_gamelist_xml_backup() {
    echo "> Creating 'gamelist-backup.xml' for '$system' ..."
    if [[ ! -f "$(dirname "$gamelist_path")/gamelist-backup.xml" ]]; then
        cp "$(dirname "$gamelist_path")/gamelist.xml" "$(dirname "$gamelist_path")/gamelist-backup.xml" > /dev/null
        return_value="$?"
        if [[ "$return_value" -eq 0 ]]; then
            echo "'gamelist-backup.xml' for '$system' created successfully!"
        else
            echo "ERROR: Couldn't copy '$(dirname "$gamelist_path")/gamelist.xml'!" >&2
            continue
        fi
    else
        echo "There is already a 'gamelist-backup.xml' for '$system'."
    fi
}


function get_sorted_lastplayed() {
    while read -r line; do
        [[ -n "$line" ]] && last_played_array+=("$line")
    done < <(sort -r <(xmlstarlet sel -t -v "/gameList/game/lastplayed" -n "$(dirname "$gamelist_path")/gamelist.xml"))
}


function reset_playcount() {
    if [[ "${#last_played_array[@]}" -eq 0 ]]; then
        echo "ERROR: No 'last played' games to remove." >&2
    else
        echo "> Removing 'last played' games for '$system' ..."
        if [[ "$nth_last_played" -lt "${#last_played_array[@]}" ]]; then
            for last_played_item in "${last_played_array[@]:$nth_last_played}"; do
                echo "$last_played_item"
                #~ xmlstarlet ed -L -u "/gameList/game[lastplayed[contains(text(),'$last_played_item')]]/playcount" -v "0" "$(dirname "$gamelist_path")/gamelist.xml"
            done
            echo "> Done!"
        else
            echo "ERROR: There aren't enough 'last played' games to remove." >&2
            echo "Try lowering the '--nth' number." >&2
            if [[ "${#last_played_array[@]}" -eq 1 ]]; then
                is_are="is"
            else
                is_are="are"
            fi
            echo "Now it's set to '$nth_last_played' and there $is_are only ${#last_played_array[@]} games in '$system'." >&2
        fi
    fi
}

function get_all_systems() {
    local all_systems=()
    local system_dir
    local i=1
    
    for system_dir in "$RP_ROMS_DIR/"*; do
        if [[ ! -L "$system_dir" ]]; then
            all_systems+=("$(basename "$system_dir")")
            ((i++))
        fi
    done
    echo "${all_systems[@]}"
}

function get_options() {
    if [[ -z "$1" ]]; then
        usage
        exit 0
    fi
    
    while [[ -n "$1" ]]; do
        case "$1" in
#H -h, --help               Print the help message and exit.
            -h|--help)
                echo
                underline "$SCRIPT_TITLE"
                echo "$SCRIPT_DESCRIPTION"
                echo
                echo "USAGE: $0 [OPTIONS]"
                echo
                echo "OPTIONS:"
                echo
                sed '/^#H /!d; s/^#H //' "$0"
                echo
                exit 0
                ;;
#H -n, --nth [number]       Set number of maximum games to show (10 by default).
            -n|--nth)
                check_argument "$1" "$2" || exit 1
                shift
                nth_last_played="$1"
                ;;
#H -s, --systems            Show dialog to select systems to limit.
            -s|--systems)                
                cmd=(dialog \
                    --backtitle "$SCRIPT_TITLE" \
                    --checklist "Select systems to limit" 15 50 15)
                    
                all_systems="$(get_all_systems)"
                IFS=" " read -r -a all_systems <<< "${all_systems[@]}"
                i=1
                for system in "${all_systems[@]}"; do
                    options+=("$i" "$system" off)
                    ((i++))
                done
                
                choices="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
                
                if [[ -z "${choices[@]}" ]]; then
                    echo "No systems selected."
                    exit 1
                fi
                
                IFS=" " read -r -a choices <<< "${choices[@]}"
                for choice in "${choices[@]}"; do
                    SYSTEMS+=("${options[choice*3-2]}")
                done
                ;;
#H -v, --version            Show script version.
            -v|--version)
                echo "$SCRIPT_VERSION"
                ;;
            *)
                echo "ERROR: Invalid option '$1'." >&2
                exit 2
                ;;
        esac
        shift
    done
}


function main() {
    if ! is_retropie; then
        echo "ERROR: RetroPie is not installed. Aborting ..." >&2
        exit 1
    fi
        
    get_options "$@"
    
    echo "Number of 'last played' games to limit is set to '$nth_last_played'."
    for system in "${SYSTEMS[@]}"; do
        last_played_array=()
        
        echo
        underline "$system"
        # Find gamelist.xml path.
        find_gamelist_xml
        #Create backup for gamelist.xml.
        create_gamelist_xml_backup
        # Populate array with <lastplayed> tags found and sort them in a descending order.
        get_sorted_lastplayed
        # Set <playcount> value to '0' for all games in 'last_played_array' that are above the number of games to limit ('nth_last_played').
        reset_playcount
    done
    echo
    echo "Done!"
}

main "$@"
