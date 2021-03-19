#!/bin/bash

##############################################################################
#    DESCRIPTION: file for auxiliary functions for the main scripts.
##############################################################################

source whales_setup/.logging.sh;

##############################################################################
# .ENV EXTRACTION
##############################################################################

function env_var() {
    local file="$WHALES_PATH/.env";
    local key="$1";
    local pattern="^$key=(.*)$";
    while read line; do
        if ! ( echo "$line" | grep -E -q "$pattern" ); then continue; fi
        echo "$( echo "$line" | sed -E "s/^$1=(.*)$/\1/g" )";
        return;
    done <<< "$( cat $file )";
    _log_fail "Argument \033[93;1m$key\033[0m not found in \033[1m$file\033[0m!";
}

##############################################################################
# GLOBAL VARIABLES
##############################################################################

export WHALES_PATH="whales_setup";

# extract from .env:
export DOCKER_IP="$( env_var DOCKER_IP )";
export DOCKER_HOST_PORT="$( env_var HOST_PORT )";
export DOCKER_CONTAINER_PORT="$( env_var CONTAINER_PORT )";
export DOCKER_IMAGE="$( env_var DOCKER_IMAGE )";
export DOCKER_CONTAINER_TEMP="$( env_var DOCKER_IMAGE )_temp";
export DOCKER_SERVICE="$( env_var DOCKER_DEFAULT_SERVICE )"; # <-- NOTE: this gets changed dynamically.
export DOCKER_TAG_EXPLORE="$( env_var DOCKER_TAG_EXPLORE )";
export DOCKER_PORTS="$DOCKER_IP:$DOCKER_HOST_PORT:$DOCKER_CONTAINER_PORT";

export DOCKER_COMPOSE_YML="$WHALES_PATH/docker-compose.yml";
export FILE_DOCKER_DEPTH="$WHALES_PATH/DOCKER_DEPTH";
# NOTE: do not use /bin/bash. Results in error under Windows.  Use \/bin\/bash, bash, sh -c bash, or sh.
export DOCKER_CMD_EXPLORE="bash";

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
# AUXILIARY METHODS: DOCKER, BASIC
##############################################################################

function run_docker_compose() {
    docker-compose --file $DOCKER_COMPOSE_YML $@;
}

function docker_create_unused_container_name() {
    local name="$DOCKER_CONTAINER_TEMP";
    k=0;
    while ( docker ps -a --format '{{.Names}}' | grep -E -q "^${name}_${k}$" ); do k=$(( $k + 1 )); done;
    echo "${name}_${k}";
}

##############################################################################
# AUXILIARY METHODS: DOCKER, SERVICES
##############################################################################

function docker_get_services() {
    pattern="^${WHALES_PATH}_";
    while read -r line; do
        ! ( echo "$line" | grep -E -q "$pattern" ) && continue;
        local columns=( $line ); ## format: name, image, tag, image_id
        echo "${columns[0]}";
    done <<< "$( run_docker_compose images )";
}

function docker_get_potential_services() {
    while read -r line; do
        echo "$line";
    done <<< "$( run_docker_compose ps --services --all )";
}

function docker_exists_service() {
    service="$1";
    pattern="^${WHALES_PATH}_${service}(|_[[:digit:]]+)$";
    while read -r name; do
        ( echo "$name" | grep -E -q "$pattern" ) && return 0;
    done <<< "$( docker_get_services )";
    return 1;
}

function docker_exists_potential_service() {
    service="$1";
    while read -r name; do
        [ "$service" == "$name" ] && return 0;
    done <<< "$( docker_get_potential_services )";
    return 1;
}

function docker_get_image_name_from_service() {
    service="$1";
    pattern="^${WHALES_PATH}_${service}(|_[[:digit:]]+)$";
    while read -r line; do
        local columns=( $line ); ## format: name, image, tag, image_id
        local name="${columns[0]}";
        local image="${columns[1]}";
        local tag="${columns[2]}";
        ( echo "$name" | grep -E -q "$pattern" ) && echo "$image:$tag" && return;
    done <<< "$( run_docker_compose images )";
}

##############################################################################
# AUXILIARY METHODS: DOCKER, CONTAINERS & IMAGES
##############################################################################

function docker_get_ids() {
    local args="$@";
    local part="$(    get_kwarg "$args" "part"    "" )";
    local key="$(     get_kwarg "$args" "key"     "" )";
    local pattern="$( get_kwarg "$args" "pattern" "" )";

    if [   "$part" == "container" ]; then
        if [ "$key" == "" ]; then key="{{.Image}}"; fi
        local format="{{.ID}}\t$key";
        local lines="$( docker ps -a --format "$format" )";
    elif [ "$part" == "image"     ]; then
        if [ "$key" == "" ]; then key="{{.Repository}}"; fi
        local format="{{.ID}}\t$key";
        local lines="$( docker images -a --format "$format" )";
    else
        _log_fail "Argument must be \033[93;1mcontainer\033[0m or \033[93;1mimage\033[0m!";
    fi

    while read -r line; do
        local columns=( $line );
        local id="${columns[0]}";
        local value="${columns[1]}";
        if ( echo "$value" | grep -E -q "$pattern" ); then echo $id; fi
    done <<< "$lines";
}

function docker_get_id() {
    local args="$@";
    local part="$(    get_kwarg "$args" "part"    "" )";
    local key="$(     get_kwarg "$args" "key"     "" )";
    local pattern="$( get_kwarg "$args" "pattern" "" )";

    local ids=( $( docker_get_ids part="$part" key="$key" pattern="$pattern" ) );
    if [ ${#ids[@]} -gt 0 ]; then
        echo "${ids[0]}";
    else
        _log_error "Could not find $part with $( [ "$key" == "" ] && echo "image name" || echo "$key" ) matching \033[93;1m$pattern\033[0m.";
        return 1;
    fi
}

function docker_get_container_id_service() {
    local name="$( docker_get_image_name_from_service "$DOCKER_SERVICE" )";
    docker_get_id part=container key="{{.Image}}" pattern="^$name$" || echo "";
}

function docker_get_image_id_service() {
    local name="$( docker_get_image_name_from_service "$DOCKER_SERVICE" )";
    docker_get_id_from_image_tag "$name";
}

function docker_get_id_from_image_tag() {
    docker_get_id part=image key="{{.Repository}}:{{.Tag}}" pattern="^$1$" || echo "";
}

function docker_exists_image_tag() {
    docker_get_id part=image key="{{.Repository}}:{{.Tag}}" pattern="^$1$" 2> $VERBOSE >> $VERBOSE && return 0 || return 1;
}

function docker_get_image_name_latest_stage() {
    local image="$DOCKER_IMAGE:$1";
    if ! ( docker_exists_image_tag "$image" ); then
        local image_service="$( docker_get_image_name_from_service "$DOCKER_SERVICE" )";
        [ "$image_service" == "" ] && _log_fail "Could not find docker image \033[1m$image\033[0m or base image \033[1m$image_service\033[0m!";
        image="$image_service";
    fi
    echo "$image";
}

##############################################################################
# AUXILIARY METHODS: DOCKER, CHECK IF RUNNING
##############################################################################

function docker_is_container_stopped() {
    local id="$1";
    container_is_running="$( docker container inspect -f '{{.State.Running}}' $id 2> $VERBOSE || echo "" )";
    container_state="$(      docker container inspect -f '{{.State.Status}}'  $id 2> $VERBOSE || echo "" )";
    ## if empty status, then container does not exist --> "stopped":
    if [ "$container_is_running" == "" ] && [ "$container_state" == "" ]; then return 0; fi
    ## else check values:
    [ "$container_is_running" == "false" ] && [ "$container_state" == "exited" ] && return 0 || return 1;
}

function wait_for_container_to_stop() {
    local name="$1";
    local displayed=false;
    ## TODO: implement `show_progressbar`?
    # tput civis; # cursor invisible
    while ! ( docker_is_container_stopped "$name" ); do
        if ! ( $displayed ); then
            _log_info "pending... $PENDING_SYMBOL" true;
        else
            _cli_trailing_message "$PENDING_SYMBOL";
        fi
        displayed=true;
        sleep $WAIT_PERIOD_IN_SECONDS;
    done
    # tput cnorm; # cursor visible
    ( $displayed ) && _cli_trailing_message "\n";
}

##############################################################################
# AUXILIARY METHODS: DOCKER, CLEANING
##############################################################################

function docker_remove_container() {
    local container="$1";
    docker stop "$container" && docker rm "$container" 2> $VERBOSE >> $VERBOSE;
}

function docker_remove_image() {
    local image="$1";
    docker rmi -f "$image" 2> $VERBOSE >> $VERBOSE;
}

function docker_remove_ids() {
    local args="$@";
    local part="$(    get_kwarg "$args" "part"    "" )";
    local key="$(     get_kwarg "$args" "key"     "" )";
    local pattern="$( get_kwarg "$args" "pattern" "" )";

    local ids="$( docker_get_ids part="$part" key="$key" pattern="$pattern" )";
    [ ${#ids[@]} -eq 0 ] && _log_info "No containers were found." && return;
    if [   "$part" == "container" ]; then
        for id in "${ids[@]}"; do
            docker_remove_container "$id" \
            && _log_info "Removed $part with id \033[93;1m$id\033[0m." \
            || _log_error "Could not remove $part with id \033[93;1m$id\033[0m.";
        done
    elif [ "$part" == "image"     ]; then
        for id in "${ids[@]}"; do
            docker_remove_image     "$id" \
            && _log_info "Removed $part with id \033[93;1m$id\033[0m." \
            || _log_error "Could not remove $part with id \033[93;1m$id\033[0m.";
        done
    fi
}

function docker_remove_all_containers() {
    while read line; do
        if [ "$line" == "" ]; then continue; fi
        local columns=( $line );
        local id="${columns[0]}";
        local names="${columns[1]}";
        local image="${columns[2]}";
        _log_info "- \033[91mremove\033[0m container $names ($id) ---> has image $image";
        docker stop "$id" && docker rm "$id" 2> $VERBOSE;
    done <<< "$( docker ps -a --format '{{.ID}}\t{{.Names}}\t{{.Image}}' )";
}

function docker_remove_all_images() {
    while read line; do
        if [ "$line" == "" ]; then continue; fi
        local columns=( $line );
        local id="${columns[0]}";
        local image="${columns[1]}";
        local tag="${columns[2]}";
        _log_info "- \033[91mremove\033[0m image $image:$tag ($id)";
        docker rmi -f "$id" 2> $VERBOSE;
    done <<< "$( docker images -a --format '{{.ID}}\t{{.Repository}}\t{{.Tag}}' )";
}

##############################################################################
# WHALE METHODS
##############################################################################

function get_docker_depth() {
    local depth=0;
    if [ -f "$FILE_DOCKER_DEPTH" ]; then
        depth="$( head -n 1 $FILE_DOCKER_DEPTH )";
        if ! ( echo "$depth" | grep -E -q "^(0|[1-9][0-9]*|-[1-9][0-9]*)$" ); then depth=1; fi
    fi
    echo $depth;
}

function is_docker() {
    local depth=$( get_docker_depth );
    [ $depth -gt 0 ] && return 0 || return 1;
}

function select_service() {
    service="$1";
    ! ( docker_exists_potential_service "$service" ) && _log_fail "Service \033[1m$service\033[0m does not exist!";
    export DOCKER_SERVICE="$service";
}

##############################################################################
# WHALE METHODS: "DECORATORS"
##############################################################################

####
# Checks if in docker, and either
# returns to script, or starts docker and calls script within docker.
#
# Usage:
#    call_within_docker <service> <tag> <save> <it> <expose_ports> <script> <params>
#
# Arguments:
#        service <string>     The name of the service in whales_setup/docker-compose.yml.
#        tag <string>         The name of the tag to be assigned to the image created.
#        save <bool>          Whether the created image is to be saved after creation
#                               / after interactive container containing image is exitted.
#        it <bool>            Whether the container is to be run interactive mode.
#        expose_ports <bool>  Whether ports are to be exposed.
#        script <string>      Path to script to be carried out in docker container.
#        params <strings>     CLI params to be passed to script.
####
function call_within_docker() {
    local metaargs=( "$@" );

    ## RETURN TO SCRIPT --- if already inside docker:
    if ( is_docker ); then
        return 0;
    else
        local service="${metaargs[0]}";
        local tag="${metaargs[1]}";
        local save=${metaargs[2]};
        local it=${metaargs[3]};
        local expose=${metaargs[4]};
        local script="${metaargs[5]}";
        local params="${metaargs[@]:6}";

        ## Set default values for empty arguments
        [ "$tag" == "" ] && tag="$DOCKER_TAG_EXPLORE";
        [ "$save" == "" ] && save=false;
        [ "$it" == "" ] && it=false;
        [ "$expose" == "" ] && expose=$it;

        ## START/ENTER DOCKER:
        _log_info "YOU ARE OUTSIDE THE DOCKER ENVIRONMENT.";
        # Force start docker servic, if not already up:
        select_service "$service";
        container_service="$( docker_get_container_id_service 2> $VERBOSE )";
        [ "$container_service" == "" ] && _log_info "FORCE-BUILD DOCKER SERVICE." && run_docker_start;
        container_service="$( docker_get_container_id_service 2> $VERBOSE )";
        [ "$container_service" == "" ] && _log_fail "In whales method \033[1mcall_within_docker\033[0m could not find service \033[1m$service\033[0m!";

        ## SET ENTRY POINT:
        local entry="$( docker_get_image_name_latest_stage "$tag" 2> $VERBOSE )";
        [ "$entry" == "" ] && _log_fail "In whales method \033[1mcall_within_docker\033[0m could not find image with tag \033[1m$tag\033[0m!";

        ## SET SAVE OPTION:
        local save_arg="$( ( $save ) && echo "--save $DOCKER_IMAGE:$tag" || echo "" )";

        ## RUN SCRIPT COMMAND WITHIN DOCKER:
        local command=". $script $params"; # alternative: "cat $script | dos2unix | bash -s -- $params";
        enter_docker --service  "$service" --enter "$entry" --command \"$command\" --it $it --expose $expose $save_arg;

        ## EXIT: do not return to script
        exit 0;
    fi
}

####
# FLAGS
# --service <string>    The name of the service in whales_setup/docker-compose.yml.
# --enter <image:tag>   If argument left empty, will overwrite original.
# [--command <string>]  Use to start container with a command.
#                       Defaults to "bash", if left empty.
# [--save]              If used, will save the container to an image upon completion.
#   <image:tag>           If argument left empty, will overwrite original.
# --it <bool>           Whether or not to run docker container interactive mode.
#   false (default)       Docker will run discretely and logs will be followed.
# --expose <bool>       Whether or not ports are to be exposed (should coincide with --it).
####
function enter_docker() {
    local metaargs="$@";
    local service="$( get_one_kwarg_space "$metaargs" "-+service" ""      )";
    local entry="$(   get_one_kwarg_space "$metaargs" "-+enter"   ""      )";
    local it=$(       get_one_kwarg_space "$metaargs" "-+it"      "false" );
    local expose=$(   get_one_kwarg_space "$metaargs" "-+expose"  ""      );
    local command="$( get_one_kwarg_space "$metaargs" "-+command" ""      )";
    local save_arg=false;
    if ( has_arg "$metaargs" "-+save" ); then save_arg=true; fi
    local image="$(   get_one_kwarg_space "$metaargs" "-+save"    ""      )";

    _log_info "ENTER DOCKER ENVIRONMENT.";
    ## Get container of service (in order to connect mounted volumes):
    select_service "$service";
    local container_service="$( docker_get_container_id_service 2> $VERBOSE )";
    [ "$container_service" == "" ] && _log_fail "In whales method \033[1menter_docker\033[0m could not find service \033[1m$service\033[0m!";

    ## Get image:tag for entry point:
    local entry_orig="$entry";
    if [ "$entry" == "" ]; then
        entry_orig="$DOCKER_IMAGE:$DOCKER_TAG_EXPLORE";
        entry="$( docker_get_image_name_latest_stage "$DOCKER_TAG_EXPLORE" 2> $VERBOSE )";
        [ "$entry" == "" ] && _log_fail "In whales method \033[1menter_docker\033[0m could not find image with tag \033[1m$tag\033[0m!";
    fi

    local id="$( docker_get_id_from_image_tag "$entry" 2> $VERBOSE )";
    [ "$id" == "" ] && _log_fail "In whales method \033[1menter_docker\033[0m could not find image for entry point, \033[1m$entry\033[0m!";
    _log_info "CONTINUE WITH IMAGE \033[92;1m$entry\033[0m (\033[93;1m$id\033[0m).";

    ## Set arguments, if empty:
    [ "$save" == "" ] && save=false;
    [ "$command" == "" ] && command="$DOCKER_CMD_EXPLORE" && it=true;
    [ "$expose" == "" ] && expose=$it;

    ## Set ports command:
    local ports_option="$( ( $expose ) && echo "-p $DOCKER_PORTS" || echo "" )";

    ################################
    # ENTER DOCKER: create container and run command
    local container_tmp="$( docker_create_unused_container_name )";
    _log_info "START TEMPORARY CONTAINER \033[92;1m$container_tmp\033[0m.";
    if ( $it ); then
        _log_info "EXECUTE COMMAND {\033[93;1m$command\033[0m} INTERACTIVELY.";
        docker run --name="$container_tmp" $ports_option --volumes-from="$container_service:rw" -it $id bash -c "$command";
    else
        _log_info "EXECUTE COMMAND {\033[93;1m$command\033[0m} NON-INTERACTIVELY.";
        docker run --name="$container_tmp" $ports_option --volumes-from="$container_service:rw" -d $id bash -c "$command";
        docker logs --follow $container_tmp;
    fi
    _log_info "WAIT FOR CONTAINER \033[92;1m$container_tmp\033[0m TO STOP.";
    wait_for_container_to_stop "$container_tmp";
    # EXIT DOCKER
    ################################

    ## Save state upon exit:
    if ( $save_arg ); then
        if [ "$image" == "" ] || [ "$image" == "$entry_orig" ]; then
            image="$entry_orig";
            _log_info "SAVE STATE TO \033[92;1m$image\033[0m (OVERWRITING).";
        else
            _log_info "SAVE STATE TO \033[92;1m$image\033[0m.";
        fi
        docker commit "$container_tmp" $image >> $VERBOSE;
    fi
    docker_remove_container "$container_tmp" 2> $VERBOSE >> $VERBOSE;
    _log_info "TEMPORARY CONTAINER \033[92;1m$container_tmp\033[0m TERMINATED.";
}

##############################################################################
# MAIN PROCESSES FOR WHALES
##############################################################################

function run_docker_start() {
    local service="$DOCKER_SERVICE";
    _log_info "START DOCKER SERVICE \033[92;1m$service\033[0m.";
    local success=false;
    run_docker_compose up --build $service && success=true;
    if ! ( $success ); then
        _log_fail "Usage of docker-compose resulted in failure.";
    fi
}

function run_docker_stop_down() {
    run_docker_compose stop;
    run_docker_compose down;
}

function run_docker_clean() {
    docker_remove_ids part=container key="{{.Names}}"               pattern="^${DOCKER_CONTAINER_TEMP}($|_[[:digit:]]+$)";
    docker_remove_ids part=image     key="{{.Repository}}:{{.Tag}}" pattern="^$DOCKER_IMAGE:.+$";
    docker image prune -a --force; ## prunes any image non used by a container and any dangling images.
}

function run_docker_clean_all() {
    _log_warn "ALL docker containers and images will be stopped and removed. That includes containers not related to this project.";
    _cli_ask "Do you wish to proceed? (y/n) ";
    read answer;
    if ( check_answer "$answer" ); then
        _log_info "STOP AND REMOVE ALL CONTAINERS";
        docker_remove_all_containers
        _log_info "REMOVE ALL CONTAINERS";
        docker_remove_all_images
    else
        _log_info "SKIPPING";
    fi
}

function get_docker_state() {
    _cli_message "";
    _cli_message "Container states:";
    docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Size}}\t{{.Status}}\t{{.CreatedAt}} ago';
    _cli_message "";
    _cli_message "Images:"
    docker images -a --format 'table {{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}';
    _cli_message "";
}
