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

# home="$(eval echo ~$user)"
home="$(find /home -type d -name RetroPie -print -quit 2> /dev/null)"
home="${home%/RetroPie}"

readonly RP_DIR="$home/RetroPie"
readonly RP_ROMS_DIR="$RP_DIR/roms"
readonly RP_MENU_DIR="$RP_DIR/retropiemenu"
readonly RP_CONFIGS_DIR="/opt/retropie/configs"
readonly ES_GAMELISTS_DIR="$RP_CONFIGS_DIR/all/emulationstation/gamelists"

readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname $0)" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_FULL="$SCRIPT_DIR/SCRIPT_NAME"
readonly SCRIPT_TITLE="Retropie Limit Last Played Games"
readonly SCRIPT_DESCRIPTION="A tool for RetroPie to limit the number of 'last played' games."


# Variables #######################################

readonly gamelist_backup_dir="gamelist-backups"
readonly gamelist_backup_file="$gamelist_backup_dir.xml"

## Flags

DEBUG_FLAG=0


# Configuration  ##################################

SYSTEMS=() # Array of systems. Add as many as needed. Wrap the systems in double quotes "" and use 1 space for separation.
nth_last_played=10 # Number of 'last played' games to limit per system (10 by default).


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


function check_lastplayed_exists() {
    if [[ "$(xmlstarlet sel -t -v "/gameList/game/lastplayed" -n "$(dirname "$gamelist_path")/gamelist.xml")" == "" ]]; then
        echo "ERROR: No <lastplayed> tag found in '"$(dirname "$gamelist_path")/gamelist.xml"'."
        return 1
    fi
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
            return 1
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
    if [[ "$DEBUG_FLAG" -eq 0 ]]; then
        echo "> Creating '$gamelist_backup_file' for '$system' ..."
        mkdir -p "$(dirname "$gamelist_path")/$gamelist_backup_dir"
        cp "$(dirname "$gamelist_path")/gamelist.xml" "$(dirname "$gamelist_path")/$gamelist_backup_dir/$(date +%F-%T)-$gamelist_backup_file" > /dev/null
        return_value="$?"
        if [[ "$return_value" -eq 0 ]]; then
            echo "'$gamelist_backup_file' for '$system' created successfully!"
        else
            echo "ERROR: Couldn't copy '$(dirname "$gamelist_path")/gamelist.xml'!" >&2
            return 1
        fi
    fi
}


function get_sorted_lastplayed() {
    check_lastplayed_exists
    while read -r line; do
        if [[ -n "$line" ]]; then
            # Add only the 'last played' games with a 'playcount' greater than 0.
            if [[ "$(xmlstarlet sel -t -v "/gameList/game[lastplayed='$line']/playcount" -n "$(dirname "$gamelist_path")/gamelist.xml")" -ne 0 ]]; then
                last_played_array+=("$line")
            fi
        fi       
    done < <(sort -r <(xmlstarlet sel -t -v "/gameList/game/lastplayed" -n "$(dirname "$gamelist_path")/gamelist.xml"))
}


function reset_playcount() {
    if [[ "${#last_played_array[@]}" -eq 0 ]]; then
        echo "No 'last played' games to remove." >&2
    else
        if [[ "${#last_played_array[@]}" -eq 1 ]]; then
            is_are="is"
            game_s="game"
        else
            is_are="are"
            game_s="games"
        fi
        echo "> Removing the 'last played' games surplus for '$system' ..."
        if [[ "$nth_last_played" -lt "${#last_played_array[@]}" ]]; then
            for last_played_item in "${last_played_array[@]:$nth_last_played}"; do
                local game_name
                game_name="$(xmlstarlet sel -t -v "/gameList/game[lastplayed='$last_played_item']/name" -n "$(dirname "$gamelist_path")/gamelist.xml")"
                echo "- $game_name"
                if [[ "$DEBUG_FLAG" -eq 0 ]]; then
                    xmlstarlet ed -L -u "/gameList/game[lastplayed[contains(text(),'$last_played_item')]]/playcount" -v "0" "$(dirname "$gamelist_path")/gamelist.xml"
                fi
            done
            echo "> Done!"
        elif [[ "$nth_last_played" -eq "${#last_played_array[@]}" ]]; then
            echo "WHOOPS! There $is_are already only ${#last_played_array[@]} $game_s in '$system'. Nothing do to here ..."
        else
            echo "ERROR: There aren't enough 'last played' games to remove." >&2
            echo "Try lowering the '--nth' number." >&2
            echo "Now it's set to '$nth_last_played' and there $is_are only ${#last_played_array[@]} $game_s in '$system'." >&2
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


function install_script_retropie_menu() {
    # if [[ ! -f "$RP_MENU_DIR/$SCRIPT_NAME" ]]; then
        cp "$SCRIPT_FULL" "$RP_MENU_DIR/$SCRIPT_NAME"
    # else
        # echo "The script is already installed in EmulationStation's Retropie menu."
    # fi
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
#H -i, --install            Install the script in EmulationStation's RetroPie menu.
            -i|--install)
                install_script_retropie_menu
                exit 0
                ;;
#H -n, --nth [number]       Set number of 'last played' games to limit per system (10 by default).
            -n|--nth)
                check_argument "$1" "$2" || exit 1
                shift
                nth_last_played="$1"
                if [[ "$nth_last_played" -eq 0 ]]; then
                    echo "ERROR: Number of 'last played' games is set to '0'. Aborting ..."
                    echo "Bye!"
                    exit 1
                fi
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
                    echo "No systems selected. Aborting ..."
                    echo "Bye!"
                    exit 1
                fi

                IFS=" " read -r -a choices <<< "${choices[@]}"
                for choice in "${choices[@]}"; do
                    SYSTEMS+=("${options[choice*3-2]}")
                done
                ;;
#H -d, --debug              Set debug mode to test the script.
            -d|--debug)
                DEBUG_FLAG=1
                ;;
#H -v, --version            Show script version.
            -v|--version)
                echo "$SCRIPT_VERSION"
                exit 0
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

    if [[ "${#SYSTEMS[@]}" -eq 0 ]]; then
        echo "No systems selected. Aborting ..."
        echo "Bye!"
        exit 1
    else
        if [[ "$DEBUG_FLAG" -eq 1 ]]; then
            echo
            echo "DEBUG MODE: ON"
            echo "No harm will done to the gamelists ;)"
            echo
        fi
        echo "Number of 'last played' games to limit is set to '$nth_last_played'."
        for system in "${SYSTEMS[@]}"; do
            last_played_array=()

            echo
            underline "$system"
            # Find gamelist.xml path.
            find_gamelist_xml || continue
            #Create backup for gamelist.xml.
            create_gamelist_xml_backup || continue
            # Populate array with <lastplayed> tags found and sort them in a descending order.
            get_sorted_lastplayed || continue
            # Set <playcount> value to '0' for all games in 'last_played_array' that are above the number of games to limit ('nth_last_played').
            reset_playcount || continue
        done
        echo
        echo "All done!"
    fi
}

main "$@"
