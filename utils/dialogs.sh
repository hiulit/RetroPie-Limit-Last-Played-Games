
#!/usr/bin/env bash
# dialogs.sh

# Variables ############################################

readonly DIALOG_BACKTITLE="$SCRIPT_TITLE"
readonly DIALOG_HEIGHT=20
readonly DIALOG_WIDTH=60
readonly DIALOG_OK=0
readonly DIALOG_CANCEL=1
readonly DIALOG_HELP=2
readonly DIALOG_EXTRA=3
readonly DIALOG_ESC=255


# Functions ###########################################

function dialog_msgbox() {
    local title="$1"
    local message="$2"
    local dialog_height="$3"
    local dialog_width="$4"
    [[ -z "$title" ]] && echo "ERROR: '${FUNCNAME[0]}' needs a title as an argument!" && exit 1
    [[ -z "$message" ]] && echo "ERROR: '${FUNCNAME[0]}' needs a message as an argument!" && exit 1
    [[ -z "$dialog_height" ]] && dialog_height=8
    [[ -z "$dialog_width" ]] && dialog_width="$DIALOG_WIDTH"
    dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$1" \
        --ok-label "OK" \
        --msgbox "$2" "$dialog_height" "$dialog_width" 2>&1 >/dev/tty
}

function dialog_yesno() {
    local title="$1"
    local message="$2"
    local dialog_height="$3"
    local dialog_width="$4"
    [[ -z "$title" ]] && echo "ERROR: '${FUNCNAME[0]}' needs a title as an argument!" && exit 1
    [[ -z "$message" ]] && echo "ERROR: '${FUNCNAME[0]}' needs a message as an argument!" && exit 1
    [[ -z "$dialog_height" ]] && dialog_height=8
    [[ -z "$dialog_width" ]] && dialog_width="$DIALOG_WIDTH"
    dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$1" \
        --yesno "$2" "$dialog_height" "$dialog_width" 2>&1 >/dev/tty
}


function dialog_choose_nth() {
    local nth
    nth="$(dialog \
            --backtitle "$DIALOG_BACKTITLE" \
            --title "$SCRIPT_TITLE" \
            --cancel-label "Exit" \
            --ok-label "Next" \
            --inputbox "Enter a number to limit the games shown in the 'last played' section." \
            15 "$DIALOG_WIDTH" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$nth" ]]; then
            if [[ "$nth" -eq 0 ]]; then
                dialog_msgbox "Error!" "The number must be greater than '0'."
                dialog_choose_nth
            else
                NTH_LAST_PLAYED="$nth"
                dialog_choose_all_systems_or_systems
            fi
        else
            dialog_msgbox "Error!" "You must enter a number."
            dialog_choose_nth
        fi
    else
        exit 0
    fi
}


function dialog_choose_all_systems_or_systems() {
    local options=()
    local menu_text
    local cmd
    local choices
    local choice

    options=(
        1 "Choose systems"
        2 "All systems"
    )
    menu_text="Choose an option."
    if [[ "$GUI_FLAG" -eq 1 ]]; then
        cmd=(dialog \
            --backtitle "$DIALOG_BACKTITLE" \
            --title "$SCRIPT_TITLE" \
            --cancel-label "Exit" \
            --extra-button \
            --extra-label "Back" \
            --menu "$menu_text" 15 "$DIALOG_WIDTH" 15)
    else
        cmd=(dialog \
            --backtitle "$DIALOG_BACKTITLE" \
            --title "$SCRIPT_TITLE" \
            --cancel-label "Exit" \
            --menu "$menu_text" 15 "$DIALOG_WIDTH" 15)
    fi
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$choice" ]]; then
            case "$choice" in
                1)
                    dialog_choose_systems
                    ;;
                2)
                    dialog_choose_all_systems
                    ;;
            esac
        else
            dialog_msgbox "Error!" "Choose an option."
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
        exit 0
    elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
        dialog_choose_nth
    fi
}


function dialog_choose_all_systems() {
    local all_systems
    local system


    all_systems="$(get_all_systems)"
    IFS=" " read -r -a all_systems <<< "${all_systems[@]}"
    for system in "${all_systems[@]}"; do
        if [[ -f "$RP_ROMS_DIR/$system/gamelist.xml" || -f "$ES_GAMELISTS_DIR/$system/gamelist.xml" ]]; then
            SYSTEMS+=("$system")
        fi
    done
}


function dialog_choose_systems() {
    local all_systems
    local system
    local i=1
    local options=()
    local cmd
    local choices
    local choice

    all_systems="$(get_all_systems)"
    IFS=" " read -r -a all_systems <<< "${all_systems[@]}"
    for system in "${all_systems[@]}"; do
        if [[ -f "$RP_ROMS_DIR/$system/gamelist.xml" || -f "$ES_GAMELISTS_DIR/$system/gamelist.xml" ]]; then
            options+=("$i" "$system" off)
            ((i++))
        fi
    done

    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "$SCRIPT_TITLE" \
        --cancel-label "Exit" \
        --extra-button \
        --extra-label "Back" \
        --checklist "Select the system/s to limit." \
        15 "$DIALOG_WIDTH" 15)

    choices="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -z "${choices[@]}" ]]; then
            dialog_msgbox "Error!" "You must select at least 1 system."
            dialog_choose_systems
        fi

        IFS=" " read -r -a choices <<< "${choices[@]}"
        for choice in "${choices[@]}"; do
            SYSTEMS+=("${options[choice*3-2]}")
        done
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
        exit 0
    elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
        dialog_choose_all_systems_or_systems
    fi
}
