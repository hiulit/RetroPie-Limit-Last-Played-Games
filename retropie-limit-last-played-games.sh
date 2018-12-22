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
readonly RP_MENU_GAMELIST="$ES_GAMELISTS_DIR/retropie/gamelist.xml"

readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname $0)" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_FULL="$SCRIPT_DIR/$SCRIPT_NAME"
readonly SCRIPT_TITLE="Retropie Limit Last Played Games"
readonly SCRIPT_DESCRIPTION="A tool for RetroPie to limit the number of 'last played' games."

readonly LOG_DIR="$SCRIPT_DIR/logs"
readonly LOG_FILE="$LOG_DIR/$(date +%F-%T).log"


# Variables #######################################

readonly gamelist_backup_dir="gamelist-backups"
readonly gamelist_backup_file="$gamelist_backup_dir.xml"

readonly rp_menu_properties=(
    "path ./$SCRIPT_NAME"
    "name Limit Last Played Games"
    "desc Limit the number of 'last played' games per system."
)

## Flags

GUI_FLAG=0
DEBUG_FLAG=0


# Configuration  ##################################

SYSTEMS=() # Array of systems. Add as many as needed. Wrap the systems in double quotes "" and use 1 space for separation.
NTH_LAST_PLAYED=10 # Number of 'last played' games to limit per system (10 by default).


# External resources ######################################

source "$SCRIPT_DIR/utils/base.sh"
source "$SCRIPT_DIR/utils/dialogs.sh"


# Functions ######################################

function escape_xml() {
    if [[ -z "$1" ]]; then
        echo "ERROR: '$FUNCNAME' needs an XML as an argument!" >&2
        exit 1
    fi
    xmlstarlet esc "$1" > /dev/null
}


function validate_xml() {
    if [[ -z "$1" ]]; then
        echo "ERROR: '$FUNCNAME' needs an XML as an argument!" >&2
        exit 1
    fi
    xmlstarlet val "$1" > /dev/null
}


function check_lastplayed_exists() {
    if [[ "$(xmlstarlet sel -t -v "/gameList/game/lastplayed" -n "$(dirname "$gamelist_path")/gamelist.xml")" == "" ]]; then
        log "ERROR: No <lastplayed> tag found in '"$(dirname "$gamelist_path")/gamelist.xml"'." >&2
        return 1
    fi
}


function find_gamelist_xml() {
    if [[ ! -f "$RP_ROMS_DIR/$system/gamelist.xml" ]]; then
        log "ERROR: '$RP_ROMS_DIR/$system/gamelist.xml' doesn't exist!" >&2
        log "> Trying '$ES_GAMELISTS_DIR/$system/gamelist.xml' ..." >&2
        if [[ ! -f "$ES_GAMELISTS_DIR/$system/gamelist.xml" ]]; then
            log "ERROR: '$ES_GAMELISTS_DIR/$system/gamelist.xml' doesn't exist!" >&2
            log "ERROR: Couldn't find any 'gamelist.xml' for '$system'." >&2
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

        # Escape special characters.
        echo "> Escaping special characters for the 'gamelist.xml' for '$system' ..."
        if escape_xml "$gamelist_path"; then
            echo "Special characters for the 'gamelist.xml' for '$system' escaped successfully!"
        else
            log "ERROR: Couldn't escape special characters for the 'gamelist.xml' for '$system'." >&2
            exit 1
        fi
        # Validate XML.
        echo "> Validating 'gamelist.xml' for '$system' ..."
        if validate_xml "$gamelist_path"; then
            echo "'gamelist.xml' for '$system' validated successfully!"
        else
            log "ERROR: Couldn't validate 'gamelist.xml' for '$system'." >&2
            exit 1
        fi
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
            log "ERROR: Couldn't copy '$(dirname "$gamelist_path")/gamelist.xml'!" >&2
            return 1
        fi
    fi
}


function get_sorted_lastplayed() {
    check_lastplayed_exists
    local last_played_line
    local game_line
    while read -r last_played_line; do
        if [[ -n "$last_played_line" ]]; then
            while read -r game_line; do
                # Add only the 'last played' games with a 'playcount' greater than 0.
                if [[ "$(xmlstarlet sel -t -v "/gameList/game[name=\"$game_line\"][lastplayed='$last_played_line']/playcount" -n "$(dirname "$gamelist_path")/gamelist.xml")" -ne 0 ]]; then
                    last_played_array+=("$game_line")
                fi
            done < <(xmlstarlet sel -t -v "/gameList/game[lastplayed='$last_played_line']/name" -n "$(dirname "$gamelist_path")/gamelist.xml")
        fi
    done < <(sort -u -r <(xmlstarlet sel -t -v "/gameList/game/lastplayed" -n "$(dirname "$gamelist_path")/gamelist.xml"))
}


function reset_playcount() {
    if [[ "${#last_played_array[@]}" -eq 0 ]]; then
        log "No 'last played' games to remove."
    else
        if [[ "${#last_played_array[@]}" -eq 1 ]]; then
            is_are="is"
            game_s="game"
        else
            is_are="are"
            game_s="games"
        fi
        echo "> Removing the 'last played' games surplus for '$system' ..."
        if [[ "$NTH_LAST_PLAYED" -lt "${#last_played_array[@]}" ]]; then
            # Games to remove.
            for last_played_item in "${last_played_array[@]:$NTH_LAST_PLAYED}"; do
                local game_name
                game_name="$last_played_item"
                log "- \"$game_name\" ... removed successfully!"
                if [[ "$DEBUG_FLAG" -eq 0 ]]; then
                    xmlstarlet ed -L -u "/gameList/game[name[contains(text(),\"$game_name\")]]/playcount" -v "0" "$(dirname "$gamelist_path")/gamelist.xml"
                fi
            done
            echo "> Done!"
            # Games to show in 'last played' section.
            log "Games that will be shown in the 'last played' section:"
            for last_played_item in "${last_played_array[@]:0:$NTH_LAST_PLAYED}"; do
                local game_name
                game_name="$last_played_item"
                log "- \"$game_name\""
            done
        elif [[ "$NTH_LAST_PLAYED" -eq "${#last_played_array[@]}" ]]; then
            log "WHOOPS! There $is_are already only ${#last_played_array[@]} $game_s in '$system'. Nothing do to here ..."
        else
            log "ERROR: There aren't enough 'last played' games to remove." >&2
            log "Try lowering the '--nth' number." >&2
            log "Now it's set to '$NTH_LAST_PLAYED' and there $is_are only ${#last_played_array[@]} $game_s in '$system'." >&2
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
            cat > "$RP_MENU_DIR/$SCRIPT_NAME" << _EOF_
#!/usr/bin/env bash
# $SCRIPT_NAME

$SCRIPT_FULL -g

_EOF_

    if ! xmlstarlet sel -t -v "/gameList/game[path='./$SCRIPT_NAME']" "$RP_MENU_GAMELIST" > /dev/null; then
        # Crete <newGame>
        xmlstarlet ed -L -s "/gameList" -t elem -n "newGame" -v "" "$RP_MENU_GAMELIST"
        for node in "${rp_menu_properties[@]}"; do
            local key
            local value
            key="$(echo $node | grep  -Eo "^[^ ]+")"
            value="$(echo $node | grep -Po "(?<= ).*")"
            if [[ -n "$value" ]]; then
                # Add nodes from $rp_menu_properties to <newGame>
                xmlstarlet ed -L -s "/gameList/newGame" -t elem -n "$key" -v "$value" "$RP_MENU_GAMELIST"
            fi
        done
        # Rename <newGame> to <game>
        xmlstarlet ed -L -r "/gameList/newGame" -v "game" "$RP_MENU_GAMELIST"
    fi
    echo "Script installed successfully!"
}


function uninstall_script_retropie_menu() {
    rm "$RP_MENU_DIR/$SCRIPT_NAME"
    xmlstarlet ed -L -d "//gameList/game[path='./$SCRIPT_NAME']" "$RP_MENU_GAMELIST"
    echo "Script uninstalled successfully!"
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
#H -u, --uninstall          Uninstall the script from EmulationStation's RetroPie menu.
            -u|--uninstall)
                uninstall_script_retropie_menu
                exit 0
                ;;
#H -n, --nth [number]       Set number of 'last played' games to limit per system (10 by default).
            -n|--nth)
                check_argument "$1" "$2" || exit 1
                shift
                NTH_LAST_PLAYED="$1"
                if [[ "$NTH_LAST_PLAYED" -eq 0 ]]; then
                    echo "ERROR: Number of 'last played' games is set to '0'. Aborting ..." >&2
                    echo "Bye!"
                    exit 1
                fi
                ;;
#H -s, --systems            Show a dialog to select the system/s to limit.
            -s|--systems)
                dialog_choose_all_systems_or_systems
                ;;
#H -g, --gui                Start the GUI.
            -g|--gui)
                GUI_FLAG=1
                dialog_choose_nth
                ;;
#H -d, --debug              Set debug mode to test the script.
            -d|--debug)
                DEBUG_FLAG=1
                DIALOG_BACKTITLE+=" (DEBUG MODE: ON)"
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

    if [[ "${#@}" -eq 1 && "$DEBUG_FLAG" -eq 1 ]]; then
        echo "'Debug mode' option must be accompanied by at least 1 other option." >&2
        exit 1
    fi

    if [[ "$GUI_FLAG" -eq 1 ]]; then
        mkdir -p "$LOG_DIR"
        chown -R "$user":"$user" "$LOG_DIR"
        touch "$LOG_FILE"
        chown -R "$user":"$user" "$LOG_FILE"
    fi

    if [[ "${#SYSTEMS[@]}" -eq 0 ]]; then
        # log "No systems selected. Aborting ..." >&2
        # echo "Bye!"
        exit 0
    else
        if [[ "$DEBUG_FLAG" -eq 1 ]]; then
            echo
            log "DEBUG MODE: ON"
            log "No harm will be done to the gamelists ;)"
            log
        fi
        log "Number of 'last played' games to limit is set to '$NTH_LAST_PLAYED'."
        for system in "${SYSTEMS[@]}"; do
            local last_played_array=()

            log
            underline "$system"
            # Find gamelist.xml path.
            find_gamelist_xml || continue
            #Create backup for gamelist.xml.
            create_gamelist_xml_backup || continue
            # Populate array with <lastplayed> tags found and sort them in a descending order.
            get_sorted_lastplayed || continue
            # Set <playcount> value to '0' for all games in 'last_played_array' that are above the number of games to limit ('$NTH_LAST_PLAYED').
            reset_playcount || continue
        done
        echo
        echo "All done!"
    fi

    if [[ "$GUI_FLAG" -eq 1 ]]; then
        local text
        local dialog_height="9"
        if [[ "$DEBUG_FLAG" -eq 1 ]]; then
            dialog_height=12
            text="DEBUG MODE: ON\n"
            text+="No harm has been done to the gamelists ;)\n\n"
        fi
        text+="All done!\n\n"
        text+="Check the log file in '$LOG_DIR'."
        dialog_msgbox "Info" "$text" "$dialog_height"
    fi
    # Check if EmulationStation is running
    if pidof emulationstation > /dev/null; then
        dialog_yesno "Info" "In order to see the changes applied to the game lists, EmulationStation need to be restarted.\n\nWould you like to restart EmulationStation?"
        local return_value="$?"
        if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
            restart_ES
        fi
    fi
}

main "$@"
