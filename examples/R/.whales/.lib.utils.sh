#!/bin/bash

##############################################################################
#    DESCRIPTION: Library of common utility functions.
#    Include using source .whales/.lib.utils.sh
##############################################################################

##############################################################################
# FOR OS SENSITIVE COMMANDS
##############################################################################

function is_linux() {
    [ "$OSTYPE" == "msys" ] && return 1 || return 0;
}

function dos_to_unix() {
    ( dos2unix --version 2> $VERBOSE >> $VERBOSE ) && dos2unix -q $1 && return;
    _log_fail "Install \033[1mdos2unix\033[0m for your system and ensure the command can be called in bash before proceeding. Cf. https://command-not-found.com/dos2unix, https://chocolatey.org/packages/dos2unix, etc.";
}

function clean_scripts_dos2unix() {
    local setup_path="$1";
    local path;
    while read path; do
        [ "$path" == "" ] && continue;
        dos_to_unix "$path";
    done <<< "$( ls -a {,$setup_path/}{,.}*.sh 2> $VERBOSE )";
}

##############################################################################
# AUXILIARY METHODS: READING CLI ARGUMENTS
##############################################################################

## EXAMPLE:
## if ( has_arg "$@" "help" ); then ...
function has_arg() {
    echo "$1" | grep -Eq "(^.*[[:space:]]|^)$2([[:space:]].*$|$)" && return 0 || return 1;
}

## EXAMPLE:
## value="$( get_kwarg "$@" "name" "N/A" )";
function get_kwarg() {
    local value="$(echo "$1" | grep -Eq "(^.*\s|^)$2=" && echo "$1" | sed -E "s/(^.*[[:space:]]|^)$2=(\"([^\"]*)\"|\'([^\']*)\'|([^[:space:]]*)).*$/\3\4\5/g" || echo "")";
    echo $value | grep -Eq "[^[:space:]]" && echo "$value" || echo "$3";
}

## EXAMPLE:
## local value;
## while read value; do
##     # do something with $value
## done <<< "$( get_all_kwargs "$@" "--data=" )";
function get_all_kwargs() {
    local arguments="$1";
    local key="$2";
    local get_one=$3;
    local default="$4"; # only used if $get_one == true
    local pattern="(^.*[[:space:]]|^)$key(\"([^\"]*)\"|\'([^\']*)\'|([^[:space:]]*)).*$";
    while ! [[ "$arguments" == "" ]]; do
        if ! ( echo "$arguments" | grep -Eq "$pattern" ); then
            arguments="";
            break;
        fi
        local value="$(echo "$arguments" | sed -E "s/$pattern/\3\4\5/g" || echo "")";
        arguments="$(echo "$arguments" | sed -E "s/$pattern/\1/g" || echo "")";
        echo "$value";
        ( $get_one ) && return 0;
    done
    ( $get_one ) && echo "$default";
}

function get_one_kwarg() {
    get_all_kwargs "$1" "$2" true "$3";
}

function get_one_kwarg_space() {
    local value="$( get_all_kwargs "$1" "$2[[:space:]]+" true "$3" )";
    ( echo "$value" | grep -Eq "^-+" ) && value="$3";
    echo "$value";
}

##############################################################################
# AUXILIARY METHODS: LOGGING AND CLI-INPUTS
##############################################################################

function check_answer() {
    echo "$1" | grep -q -E -i "^(y|yes|j|ja|1)$";
}

function _cli_ask() {
    echo -ne "$1" >> $OUT;
}

function _cli_trailing_message() {
    echo -ne "$1" >> $OUT;
}

function _cli_message() {
    if [ "$2" == "true" ]; then
        _cli_trailing_message "$1";
    else
        echo -e "$1" >> $OUT;
    fi
}

function _log_info() {
    _cli_message "${LOGGINGPREFIX}[\033[94;1mINFO\033[0m] $1" $2;
}

function _log_debug() {
    _cli_message "${LOGGINGPREFIX}[\033[95;1mDEBUG\033[0m] $1" $2;
    if ! [ -f "$PATH_LOGS/$FILENAME_LOGS_DEBUG" ]; then
        mkdir "$PATH_LOGS" 2> $VERBOSE;
        touch "$PATH_LOGS/$FILENAME_LOGS_DEBUG";
    fi
    echo "$1" >> "$PATH_LOGS/$FILENAME_LOGS_DEBUG";
}

function _log_warn() {
    _cli_message "${LOGGINGPREFIX}[\033[93;1mWARNING\033[0m] $1" $2;
}

function _log_error() {
    if [ "$2" == "true" ]; then
        echo -ne "${LOGGINGPREFIX}[\033[91;1mERROR\033[0m] $1" >> $ERR;
    else
        echo -e "${LOGGINGPREFIX}[\033[91;1mERROR\033[0m] $1" >> $ERR;
    fi
}

function _log_fail() {
    _log_error "$1" $2;
    exit 1;
}

##############################################################################
# AUXILIARY METHODS: HELP
##############################################################################

function _help_cli_key_values() {
    local arguments=( "$@" );
    local key="${arguments[0]}";
    local indent="${arguments[1]}";
    local values="";
    for arg in "${arguments[@]:2}"; do
        if ! [ "$values" == "" ]; then values="$values|"; fi
        values="$values\033[92;1m$arg\033[0m";
    done
    local cmd="\033[93;1m$key\033[0m$indent$values";
    echo "$cmd";
}

function _help_cli_key_description() {
    local arguments=( "$@" );
    local key="${arguments[0]}";
    local indent="${arguments[1]}";
    local descr="${arguments[@]:2}";
    local cmd="\033[93;1m$key\033[0m$indent\033[2;3m$descr\033[0m";
    echo "$cmd";
}

function _help_cli_values() {
    local arguments=( "$@" );
    local cmd="";
    for arg in "${arguments[@]}"; do
        ! [ "$cmd" == "" ] && cmd="$cmd|";
        cmd="$cmd\033[92;1m$arg\033[0m";
    done
    echo "$cmd";
}

##############################################################################
# AUXILIARY METHODS: PROGRESSBAR
##############################################################################

function show_progressbar() {
    local pid=$1 # Process Id of the previous running command

    function shutdown() {
        tput cnorm; # reset cursor
    }

    function cursorBack() {
        echo -en "\033[$1D";
    }

    trap shutdown EXIT;

    local displayed=false;
    # tput civis; # cursor invisible
    while kill -0 $pid 2> $VERBOSE; do
        if [ "$displayed" == "false" ]; then
            _log_info "pending... $PENDING_SYMBOL" "true";
            displayed=true;
        else
            _cli_trailing_message "$PENDING_SYMBOL";
        fi
        sleep $WAIT_PERIOD_IN_SECONDS;
    done
    # tput cnorm; # cursor visible
    wait $pid;
    local success=$?;
    [ "$displayed" == "true" ] && _cli_trailing_message "\n";
    return $success;
}

##############################################################################
# AUXILIARY METHODS: STRINGS
##############################################################################

function _trim() {
    local line="$1";
    ! ( echo "$line" | grep -Eq "[^[:space:]]" ) && return;
    echo "$line" | sed -E "s/^[[:space:]]*(.*[^[:space:]]+)[[:space:]]*$/\1/g";
}

function to_lower() {
    echo "$(echo "$1" |tr '[:upper:]' '[:lower:]')";
}

function to_upper() {
    echo "$(echo "$1" |tr '[:lower:]' '[:upper:]')";
}

## $1 = full line entry.
## example:
## if (is_comment "$line"); then ...
function is_comment() {
    echo "$1" | grep -Eq "^\s*\#" && return 0 || return 1;
}

## Replaces all occurrences of ~ with $HOME.
## NOTE: use / to replace first, // to replace all.
function expand_path() {
    echo "${1//\~/$HOME}";
}

##############################################################################
# AUXILIARY METHODS: JSON
##############################################################################

# Only for json dictionaries of type Dict[str,(str|number|bool)] with no commas in values:
function json_dictionary_kwargs_fast() {
    local json="$1";
    # Remove outer braces and all quotation marks
    json="$( echo "$json" | sed -E "s/^\{|\"|\}$//g" )";
    local pattern="([^:]*):([^,]*)(,(.*$)|($))";
    while ! [[ "$json" == "" ]]; do
        # Check if json ~ ^(|.*,)key:...
        ! ( echo "$json" | grep -Eq "$pattern" ) && break;
        local key="$(   echo "$json" | sed -E "s/$pattern/\1/g"   )";
        local value="$( echo "$json" | sed -E "s/$pattern/\2/g"   )";
        json="$(        echo "$json" | sed -E "s/$pattern/\4\5/g" )";
        echo "$key $value"
    done
}

# Only for json dictionaries of type Dict[str,(str|number|bool)],
# Applies safer pattern matching.
function json_dictionary_kwargs() {
    local json="$1";
    # Remove outer braces:
    json="$( echo "$json" | sed -E "s/^\{|\}$//g" )";
    # Recursively extract keys and values from right-to-left:
    local keypattern="[a-zA-Z0-9\.-_]";
    local pattern="((^.*),|(^))\"($keypattern*)\":(\"(.*)\"|(.*))$";
    function json_dictionary_kwargs_recursive() {
        local json="$1";
        [ "$json" == "" ] && return;
        ! ( echo "$json" | grep -Eq "$pattern" ) && return;
        local key="$(   echo "$json" | sed -E "s/$pattern/\4/g"   )";
        local value="$( echo "$json" | sed -E "s/$pattern/\6\7/g"   )";
        json="$(        echo "$json" | sed -E "s/$pattern/\2\3/g" )";
        json_dictionary_kwargs_recursive "$json";
        echo "$key $value";
    }
    json_dictionary_kwargs_recursive "$json";
}

##############################################################################
# AUXILIARY METHODS: YAML CONFIG FILES
##############################################################################

function has_config_key() {
    file="$1";
    key="$2";
    if ! [ -f $file ]; then
        _log_fail "Config file \033[1m$file\033[0m not found!";
    fi
    cat $file | dos2unix | grep -Eq  "^\s*$key:" && return 0 || return 1;
}

function get_config_key_value() {
    config="$1";
    key="$2";
    default="$3";
    if ! [ -f $config ]; then
        _log_fail "Config file \033[1m$config\033[0m not found!";
    fi
    ## use sed -n .... /p to delete all non-matching lines
    ## store matches in an array
    lines=( $(cat "$config" | dos2unix | sed -n -E "s/^[[:space:]]*$key:(.*)$/\1/p") );
    ## extract the 0th entry, if it exists, otherwise return default.
    echo "$([ ${#lines[@]} -gt 0 ] && echo "$(_trim "${lines[0]}")" || echo "$default")";
}

function get_config_boolean() {
    key="$1";
    default="$2";
    value="$(get_config_key_value "$key" "$default")";
    [ "$value" == "true" ] && echo 1 || echo 0;
}

##############################################################################
# AUXILIARY METHODS: FILES AND FOLDERS
##############################################################################

function copy_file() {
    args="$@"
    file="$(get_kwarg "$args" "file" "")";
    folder_from_formatted="$(get_kwarg "$args" "from" "")";
    folder_to_formatted="$(get_kwarg "$args" "to" "")";
    rename="$(get_kwarg "$args" "rename" "")";

    folder_from="$(expand_path "$folder_from_formatted")";
    folder_to="$(expand_path "$folder_to_formatted")";

    if ! [ -d "$folder_from" ]; then
        _log_error "For copy-file command: source folder \033[1m$folder_from_formatted\033[0m does not exist!";
        return;
    fi
    if ! [ -d "$folder_to" ]; then
        _log_error "For copy-file command: destination folder \033[1m$folder_to_formatted\033[0m does not exist!";
        return;
    fi
    if ! [ -f "$folder_from/$file" ]; then
        _log_error "For copy-file command: file \033[1m$folder_from_formatted/$file\033[0m could not be found!";
        return;
    fi
    if [ "$rename" == "" ]; then
        rename="$file";
    fi

    cp "$folder_from/$file" "$folder_to/$rename" && _log_info "Copied \033[1m$folder_from_formatted/$file\033[0m to \033[1m$folder_to_formatted/$rename\033[0m." || _log_fail "Copy-file command failed.";
}

function copy_dir() {
    args="$@"
    dir="$(get_kwarg "$args" "dir" "")";
    folder_from_formatted="$(get_kwarg "$args" "from" "")";
    folder_to_formatted="$(get_kwarg "$args" "to" "")";

    folder_from="$(expand_path "$folder_from_formatted")";
    folder_to="$(expand_path "$folder_to_formatted")";

    if ! [ -d "$folder_from" ]; then
        _log_error "For copy-dir command: source folder \033[1m$folder_from_formatted\033[0m does not exist!";
        return;
    fi
    if ! [ -d "$folder_to" ]; then
        _log_error "For copy-dir command: destination folder \033[1m$folder_to_formatted\033[0m does not exist!";
        return;
    fi
    if ! [ -d "$folder_from/$dir" ]; then
        _log_error "For copy-dir command: directory \033[1m$folder_from_formatted/$dir\033[0m could not be found!";
        return;
    fi

    cp -r "$folder_from/$dir" "$folder_to" && _log_info "Copied \033[1m$folder_from_formatted/$dir\033[0m to \033[1m$folder_to_formatted/$rename\033[0m." || _log_fail "Copy-dir command failed.";
}

function remove_file() {
    fname="$1";
    [ -f "$fname" ] && rm -f "$fname" && _log_info "Removed \033[1m$fname.\033[0m" || _log_info "Nothing to remove: \033[1m$fname\033[0m does not exist.";
}