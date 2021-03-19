#!/bin/bash

##############################################################################
#    DESCRIPTION: file for auxiliary functions for the main scripts.
##############################################################################

source whales_setup/.lib.logging.sh;

##############################################################################
# GLOBAL VARIABLES
##############################################################################

# periodic waiting time to check a process;
export WAIT_PERIOD_IN_SECONDS=1;
export PENDING_SYMBOL="#";

##############################################################################
# FOR OS SENSITIVE COMMANDS
##############################################################################

function is_linux() {
    [ "$OSTYPE" == "msys" ] && return 1 || return 0;
}

##############################################################################
# AUXILIARY METHODS: READING CLI ARGUMENTS
##############################################################################

## $1 = full argument string, $2 = argument.
## EXAMPLE:
## if ( has_arg "$@" "help" ); then ...
function has_arg() {
    echo "$1" | grep -E -q "^(.*\s|)$2(\s.*|)$" && return 0 || return 1;
}

## $1 = full argument string, $2 = key, $3 = default value.
## EXAMPLE:
## value="$( get_kwarg "$@" "name" "N/A" )";
function get_kwarg() {
    value="$(echo "$1" | grep -E -q "(^.*\s|^)$2=" && echo "$1" | sed -E "s/(^.*[[:space:]]|^)$2=(\"([^\"]*)\"|\'([^\']*)\'|([^[:space:]]*)).*$/\3\4\5/g" || echo "")";
    echo $value | grep -E -q "[^[:space:]]" && echo "$value" || echo "$3";
}

## $1 = full argument string
## $2 = key (including connecter: either = or space)
## $3 = true/false whether to stop after first value (default=false).
## $4 = default value, if $4=true and no value obtained
## EXAMPLE:
## while read value; do
##     # do something with $value
## done <<< "$( get_all_kwargs "$@" "--data=" )";
function get_all_kwargs() {
    arguments="$1";
    key="$2";
    get_one=$([ "$3" == "" ] && echo "false" || echo "$3");
    default="$4";

    pattern="(^.*[[:space:]]|^)$key(\"([^\"]*)\"|\'([^\']*)\'|([^[:space:]]*)).*$";
    while ! [[ "$arguments" == "" ]]; do
        if ! ( echo "$arguments" | grep -E -q "$pattern" ); then
            arguments="";
            break;
        fi
        value="$(echo "$arguments" | sed -E "s/$pattern/\3\4\5/g" || echo "")";
        arguments="$(echo "$arguments" | sed -E "s/$pattern/\1/g" || echo "")";
        echo "$value";
        if [ "$get_one" == "true" ]; then return 0; fi
    done;
    if [ "$get_one" == "true" ]; then echo "$default"; fi
}

## $1 = full argument string
## $2 = key (including connecter: either = or space)
## $3 = default value.
function get_one_kwarg() {
    get_all_kwargs "$1" "$2" true "$3";
}

## $1 = full argument string
## $2 = key (no delimeter)
## $3 = default value.
function get_one_kwarg_space() {
    value="$(get_one_kwarg "$1" "$2[[:space:]]+" "$3")";
    if ( echo "$value" | grep -E -q "^-+" ); then value="$3"; fi
    echo "$value";
}

##############################################################################
# AUXILIARY METHODS: LOGGING AND CLI-INPUTS
##############################################################################

function check_answer() {
    echo "$1" | grep -q -E -i "^(y|yes|j|ja|1)$";
}

function _cli_ask() {
    echo -ne "$1" >> "$OUT";
}

function _cli_trailing_message() {
    echo -ne "$1" >> "$OUT";
}

function _cli_message() {
    if [ "$2" == "true" ]; then
        _cli_trailing_message "$1";
    else
        echo -e "$1" >> "$OUT";
    fi
}

function _log_info() {
    _cli_message "[\033[94;1mINFO\033[0m] $1" $2;
}

function _log_debug() {
    _cli_message "[\033[95;1mDEBUG\033[0m] $1" $2;
    if ! [ -f "$PATH_LOGS/$DEBUG" ]; then
        mkdir "$PATH_LOGS" 2> $VERBOSE;
        touch "$PATH_LOGS/$DEBUG";
    fi
    echo "$1" >> $PATH_LOGS/$DEBUG;
}

function _log_warn() {
    _cli_message "[\033[93;1mWARNING\033[0m] $1" $2;
}

function _log_error() {
    if [ "$2" == "true" ]; then
        echo -ne "[\033[91;1mERROR\033[0m] $1" >> "$ERR";
    else
        echo -e "[\033[91;1mERROR\033[0m] $1" >> "$ERR";
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
    arguments=( "$@" );
    key="${arguments[0]}";
    indent="${arguments[1]}";
    values="";
    for arg in "${arguments[@]:2}"; do
        if ! [ "$values" == "" ]; then values="$values|"; fi
        values="$values\033[92;1m$arg\033[0m";
    done
    cmd="\033[93;1m$key\033[0m$indent$values";
    echo "$cmd";
}

function _help_cli_key_description() {
    arguments=( "$@" );
    key="${arguments[0]}";
    indent="${arguments[1]}";
    descr="${arguments[@]:2}";
    cmd="\033[93;1m$key\033[0m$indent\033[2;3m$descr\033[0m";
    echo "$cmd";
}

function _help_cli_values() {
    arguments=( "$@" );
    cmd="";
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
    pid=$1 # Process Id of the previous running command

    function shutdown() {
        tput cnorm; # reset cursor
    }

    function cursorBack() {
        echo -en "\033[$1D";
    }

    trap shutdown EXIT;

    displayed=false;
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
    success=$?;
    [ "$displayed" == "true" ] && _cli_trailing_message "\n";
    return $success;
}

##############################################################################
# AUXILIARY METHODS: STRINGS
##############################################################################

function _trim() {
    line="$1";
    echo "$line" | grep -E -q "[^[:space:]]" && echo "$line" | sed -E "s/^[[:space:]]*(.*[^[:space:]]+)[[:space:]]*$/\1/g" || echo "";
}

function to_lower() {
    echo "$(echo $1 |tr '[:upper:]' '[:lower:]')";
}

function to_upper() {
    echo "$(echo $1 |tr '[:lower:]' '[:upper:]')";
}

## $1 = full line entry.
## example:
## if (is_comment "$line"); then ...
function is_comment() {
    line="$1";
    echo "$line" | grep -E -q "^\s*\#" && return 0 || return 1;
}

## Replaces all occurrences of ~ with $HOME.
## NOTE: use / to replace first, // to replace all.
function expand_path() {
    echo "${1//\~/$HOME}";
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

##############################################################################
# AUXILIARY METHODS: YAML CONFIG FILES
##############################################################################

function has_config_key() {
    file="$1";
    key="$2";
    if ! [ -f $file ]; then
        _log_fail "Config file \033[1m$file\033[0m not found!";
    fi
    cat $file | dos2unix | grep -E -q  "^\s*$key:" && return 0 || return 1;
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
