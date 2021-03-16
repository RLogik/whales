#!/bin/bash

##############################################################################
#    DESCRIPTION: file for auxiliary functions for the main scripts.
##############################################################################

. .logging.sh;

####
# NOTE: must coincide with contents of .env + docker-compose.yml:
export DOCKER_IP="127.0.0.1";
export DOCKER_HOST_PORT="9000";
export DOCKER_CONTAINER_PORT="9000";
export DOCKER_SERVICE_MAIN="whales";
####
export FILE_DOCKER_DEPTH="DOCKER_DEPTH";
export DOCKER_IMAGE="whales";
export DOCKER_TAG_BASE="base";
export DOCKER_TAG_EXPLORE="explore";
export DOCKER_CONTAINER_TEMP="whales_temp";
####
# NOTE: do not use /bin/bash. Results in error under Windows.
# Use \/bin\/bash, bash, sh -c bash, or sh.
export DOCKER_CMD_EXPLORE="bash";
####
export DOCKER_PORTS="$DOCKER_IP:$DOCKER_HOST_PORT:$DOCKER_CONTAINER_PORT";

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
# DOCKER
##############################################################################

function get_docker_depth() {
    depth=1;
    if [ -f "$FILE_DOCKER_DEPTH" ]; then depth="$(head -n 1 $FILE_DOCKER_DEPTH)"; fi
    if ! ( echo "$depth" | grep -E -q "^(0|[1-9][0-9]*|-[1-9][0-9]*)$" ); then depth=1; fi
    echo $depth;
}

function is_docker() {
    depth=$(get_docker_depth);
    [ $depth -gt 0 ] && return 0 || return 1;
}

########################################
# Checks if in docker, and either
# returns to script, or starts docker and calls script within docker.
# Usage:
#     call_within_docker <base_tag> <tag> <save> <it> <expose_ports> <script> <params>
function call_within_docker() {
    metaargs=( "$@" );

    ## RETURN TO SCRIPT --- if already inside docker:
    if ( is_docker ); then
        return 0;
    else
        base_tag="${metaargs[0]}";
        tag="${metaargs[1]}";
        save="${metaargs[2]}";
        it="${metaargs[3]}";
        expose_ports="${metaargs[4]}";
        script="${metaargs[5]}";
        params="${metaargs[@]:6}";

        ## START/ENTER DOCKER:
        _log_info "YOU ARE OUTSIDE THE DOCKER ENVIRONMENT.";
        # Force start docker servic, if not already up:
        set_base_tag "$base_tag"; ## <-- set base tag
        container_base="$(docker_get_container_id_base 2> $VERBOSE)";
        if [ "$container_base" == "" ]; then
            _log_info "FORCE-BUILD DOCKER SERVICE.";
            . .docker.sh --base "$base_tag" --up --mount;
        fi

        ## SET ENTRY POINT:
        [ "$save" == "true" ] && save_arg="--save $DOCKER_IMAGE:$tag" || save_arg="";
        entry="$(docker_get_image_name_latest_stage "$tag")";

        ## RUN SCRIPT COMMAND WITHIN DOCKER:
        command=". $script $params"; # alternative: "cat $script | dos2unix | bash -s -- $params";
        . .docker.sh --base "$base_tag" --command=\"$command\" --enter "$entry" --it="$it" --expose="$expose_ports" $save_arg;

        ## EXIT: do not return to script
        exit 0;
    fi
}

##############################################################################
# AUXILIARY METHODS: READING CLI ARGUMENTS
##############################################################################

## $1 = full argument string, $2 = argument.
## example:
## if (has_arg "$@" "help"); then ...
function has_arg() {
    echo "$1" | grep -E -q "^(.*\s|)$2(\s.*|)$" && return 0 || return 1;
}

## $1 = full argument string, $2 = key, $3 = default value.
## example:
## value="$(get_kwarg "$@" "name" "N/A")";
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
## done <<< "$(get_all_kwargs "$@" "--data=")";
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
    _cli_message "[\033[94;1mINFO\033[0m] $1" "$2";
}

function _log_debug() {
    _cli_message "[\033[95;1mDEBUG\033[0m] $1" "$2";
    if ! [ -f "$PATH_LOGS/$DEBUG" ]; then
        mkdir "$PATH_LOGS" 2> $VERBOSE;
        touch "$PATH_LOGS/$DEBUG";
    fi
    echo "$1" >> $PATH_LOGS/$DEBUG;
}

function _log_warn() {
    _cli_message "[\033[93;1mWARNING\033[0m] $1" "$2";
}

function _log_error() {
    if [ "$2" == "true" ]; then
        echo -ne "[\033[91;1mERROR\033[0m] $1" >> "$ERR";
    else
        echo -e "[\033[91;1mERROR\033[0m] $1" >> "$ERR";
    fi
}

function _log_fail() {
    _log_error "$1" "$2"
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
    cmd="";
    for arg in "$@"; do
        if ! [ "$cmd" == "" ]; then cmd="$cmd|"; fi
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
# AUXILIARY METHODS: YAML CONFIG FILES
##############################################################################

function has_config_key() {
    if ! [ -f $CONFIG_FILE ]; then
        _log_fail "Config file \033[1m$CONFIG_FILE\033[0m not found!";
    fi
    cat $CONFIG_FILE | dos2unix | grep -E -q  "^\s*$key:" && return 0 || return 1;
}

function get_config_key_value() {
    key="$1";
    default="$2";
    if ! [ -f $CONFIG_FILE ]; then
        _log_fail "Config file \033[1m$CONFIG_FILE\033[0m not found!";
    fi
    ## use sed -n .... /p to delete all non-matching lines
    ## store matches in an array
    lines=( $(cat "$CONFIG_FILE" | dos2unix | sed -n -E "s/^[[:space:]]*$key:(.*)$/\1/p") );
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

##############################################################################
# AUXILIARY METHODS: DOCKER
##############################################################################

function set_base_tag() {
    tag="$1";
    export DOCKER_TAG_BASE="$tag";
}

function docker_get_ids() {
    args="$@";
    part="$(get_kwarg "$args" "part" "")";
    key="$(get_kwarg "$args" "key" "")";
    pattern="$(get_kwarg "$args" "pattern" "")";

    if [ "$part" == "container" ]; then
        if [ "$key" == "" ]; then key="{{.Image}}"; fi
        format="{{.ID}}\t$key";
        lines="$(docker ps -a --format "$format")";
    elif [ "$part" == "image" ]; then
        if [ "$key" == "" ]; then key="{{.Repository}}"; fi
        format="{{.ID}}\t$key";
        lines="$(docker images -a --format "$format")";
    else
        _log_fail "Argument must be \033[93;1mcontainer\033[0m or \033[93;1mimage\033[0m!";
    fi

    while read -r line; do
        columns=( $line );
        id="${columns[0]}";
        value="${columns[1]}";
        if ( echo "$value" | grep -E -q "$pattern" ); then
            echo $id;
        fi
    done <<< "$lines";
}

function docker_get_id() {
    args="$@";
    part="$(get_kwarg "$args" "part" "")";
    key="$(get_kwarg "$args" "key" "")";
    pattern="$(get_kwarg "$args" "pattern" "")";

    ids=( $(docker_get_ids part="$part" key="$key" pattern="$pattern") );
    if [ ${#ids[@]} -gt 0 ]; then
        echo "${ids[0]}";
    else
        _log_error "Could not find $part with $([ "$key" == "" ] && echo "image name" || echo "$key") matching \033[93;1m$pattern\033[0m.";
        return 1;
    fi
}

function docker_get_container_id_base() {
    docker_get_id part=container key="{{.Image}}" pattern="^$DOCKER_IMAGE:$DOCKER_TAG_BASE$" || echo "";
}

function docker_get_id_from_image_tag() {
    docker_get_id part=image key="{{.Repository}}:{{.Tag}}" pattern="^$1$" || echo "";
}

function docker_exists_image_tag() {
    docker_get_id part=image key="{{.Repository}}:{{.Tag}}" pattern="^$1$" 2> $VERBOSE >> $VERBOSE && return 0 || return 1;
}

function docker_get_image_name_latest_stage() {
    tag="$1";
    if [ "$tag" == "explore" ] && ! ( docker_exists_image_tag "$DOCKER_IMAGE:$tag" ); then tag="pipe"; fi
    if [ "$tag" == "pipe" ] && ! ( docker_exists_image_tag "$DOCKER_IMAGE:$tag" ); then tag="base"; fi
    echo "$DOCKER_IMAGE:$tag";
}

function docker_is_container_stopped() {
    id="$1";
    container_is_running="$(docker container inspect -f '{{.State.Running}}' $id 2> $VERBOSE || echo "")";
    container_state="$(docker container inspect -f '{{.State.Status}}' $id 2> $VERBOSE || echo "")";
    ## if empty status, then container does not exist --> "stopped":
    if [ "$container_is_running" == "" ] && [ "$container_state" == "" ]; then return 0; fi
    ## else check values:
    [ "$container_is_running" == "false" ] && [ "$container_state" == "exited" ] && return 0 || return 1;
}

function wait_for_container_to_stop() {
    name="$1";
    displayed=false;
    # tput civis; # cursor invisible
    while ! ( docker_is_container_stopped "$name" ); do
        if [ "$displayed" == "false" ]; then
            _log_info "pending... $PENDING_SYMBOL" "true";
            displayed=true;
        else
            _cli_trailing_message "$PENDING_SYMBOL";
        fi
        sleep $WAIT_PERIOD_IN_SECONDS;
    done
    # tput cnorm; # cursor visible
    [ "$displayed" == "true" ] && _cli_trailing_message "\n";
}

function docker_create_unused_container_name() {
    name="$DOCKER_CONTAINER_TEMP";
    k=0;
    while ( docker ps -a --format '{{.Names}}' | grep -E -q "^${name}_${k}$" ); do k=$(( $k + 1 )); done;
    echo "${name}_${k}";
}

function docker_remove_ids() {
    args="$@";
    part="$(get_kwarg "$args" "part" "")";
    key="$(get_kwarg "$args" "key" "")";
    pattern="$(get_kwarg "$args" "pattern" "")";

    ids="$(docker_get_ids part="$part" key="$key" pattern="$pattern")";
    for id in ${ids[@]}; do
        if [ "$part" == "container" ]; then
            docker_remove_container "$id" && _log_info "Removed $part with id \033[93;1m$id\033[0m." || _log_error "Could not remove $part with id \033[93;1m$id\033[0m.";
        elif [ "$part" == "image" ]; then
            docker_remove_image "$id" && _log_info "Removed $part with id \033[93;1m$id\033[0m." || _log_error "Could not remove $part with id \033[93;1m$id\033[0m.";
        fi
    done
    if [ ${#ids[@]} -eq 0 ]; then _log_info "No containers were found."; fi
}

function docker_remove_container() {
    container="$1";
    docker stop $container && docker rm "$container" 2> $VERBOSE >> $VERBOSE;
}

function docker_remove_image() {
    image="$1";
    docker rmi -f "$image" >> $VERBOSE 2> $VERBOSE >> $VERBOSE;
}

function docker_remove_all_containers() {
    while read line; do
        if [ "$line" == "" ]; then continue; fi
        columns=( $line );
        id="${columns[0]}";
        names="${columns[1]}";
        image="${columns[2]}";
        _log_info "- \033[91mremove\033[0m container $names ($id) ---> has image $image";
        docker stop $id && docker rm $id 2> $VERBOSE;
    done <<< "$( docker ps -a --format '{{.ID}}\t{{.Names}}\t{{.Image}}' )";
}

function docker_remove_all_images() {
    while read line; do
        if [ "$line" == "" ]; then continue; fi
        columns=( $line );
        id="${columns[0]}";
        image="${columns[1]}";
        tag="${columns[2]}";
        _log_info "- \033[91mremove\033[0m image $image:$tag ($id)";
        docker rmi -f $id 2> $VERBOSE;
    done <<< "$( docker images -a --format '{{.ID}}\t{{.Repository}}\t{{.Tag}}' )";
}

##############################################################################
# MAIN METHODS: PROCESSES
##############################################################################

function run_setup() {
    _log_warn "Setup process not yet implemented!";
    # < your code here > #
}

function run_test_unit() {
    _log_warn "Unit tests not yet implemented!";
    # < your code here > #
}

function run_main() {
    _log_warn "Main process not yet implemented!";
    # < your code here > #
}

function run_explore_console() {
    ## start interaction:
    _log_info "READY TO EXPLORE.";
    $DOCKER_CMD_EXPLORE;
}

function run_clean_docker() {
    . .docker.sh --clean;
}

function run_clean_docker_all() {
    . .docker.sh --clean-all;
}
