#!/bin/bash

##############################################################################
#    DESCRIPTION: Library of methods for Whales
#    Include using source whales_setup/.lib.whales.sh
##############################################################################

source whales_setup/.lib.utils.sh;
export WHALES_PATH="whales_setup";

##############################################################################
# GLOBAL VARIABLES
##############################################################################

# extract from .env:
export WHALES_DOCKER_IP="$(             env_var "$WHALES_PATH/.env" IP )";
export WHALES_DOCKER_PORT_HOST="$(      env_var "$WHALES_PATH/.env" PORT_HOST )";
export WHALES_DOCKER_PORT_CONTAINER="$( env_var "$WHALES_PATH/.env" PORT_CONTAINER )";
export WHALES_DOCKER_SERVICE="$(        env_var "$WHALES_PATH/.env" DEFAULT_SERVICE )";   # NOTE: This get changed dynamically.
export WHALES_DOCKER_IMAGE="$(          env_var "$WHALES_PATH/.env" DEFAULT_IMAGE )";     # ""
export WHALES_DOCKER_CONTAINER="$(      env_var "$WHALES_PATH/.env" DEFAULT_CONTAINER )"; # ""
export WHALES_DOCKER_TAG_EXPLORE="$(    env_var "$WHALES_PATH/.env" TAG_EXPLORE )";

export WHALES_DOCKER_PORTS="$WHALES_DOCKER_IP:$WHALES_DOCKER_PORT_HOST:$WHALES_DOCKER_PORT_CONTAINER";
export WHALES_DOCKER_CONTAINER_TEMP="whales_temp";
export WHALES_DOCKER_COMPOSE_YML="$WHALES_PATH/docker-compose.yml";
export WHALES_FILE_DOCKER_DEPTH="$WHALES_PATH/DOCKER_DEPTH";

# NOTE: do not use /bin/bash. Results in error under Windows.  Use \/bin\/bash, bash, sh -c bash, or sh.
export WHALES_DOCKER_CMD_EXPLORE="bash";

##############################################################################
# AUXILIARY METHODS: DOCKER, BASIC
##############################################################################

function run_docker_compose() {
    docker-compose --file "$WHALES_DOCKER_COMPOSE_YML" $@;
}

function docker_create_unused_container_name() {
    local name="$WHALES_DOCKER_CONTAINER_TEMP";
    k=0;
    while ( docker ps -a --format '{{.Names}}' | grep -E -q "^${name}_${k}$" ); do k=$(( $k + 1 )); done;
    echo "${name}_${k}";
}

##############################################################################
# AUXILIARY METHODS: DOCKER, SERVICES
##############################################################################

function docker_get_services() {
    local pattern="^${WHALES_PATH}_";
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
    local service="$1";
    local pattern="^${WHALES_PATH}_${service}($|_[[:digit:]]+$)";
    while read -r name; do
        ( echo "$name" | grep -E -q "$pattern" ) && return 0;
    done <<< "$( docker_get_services )";
    return 1;
}

function docker_exists_potential_service() {
    local service="$1";
    while read -r name; do
        [ "$service" == "$name" ] && return 0;
    done <<< "$( docker_get_potential_services )";
    return 1;
}

function docker_get_service_image_plus_tag() {
    local service="$1";
    [ "$service" == "" ] && return;
    local pattern="^${WHALES_PATH}_${service}($|_[[:digit:]]+$)";
    while read -r line; do
        local columns=( $line ); ## format: name, image, tag, image_id
        local name="${columns[0]}";
        local image="${columns[1]}";
        local tag="${columns[2]}";
        ( echo "$name" | grep -E -q "$pattern" ) && echo "$image:$tag" && return;
    done <<< "$( run_docker_compose images )";
    _log_fail "Could not find any images for service \033[1m$service\033[0m!";
}

function docker_get_service_image() {
    local service="$1";
    local image_service="$( docker_get_service_image_plus_tag "$service" 2> $VERBOSE )";
    [ "$image_service" == "" ] && _log_fail "Could not find image associated to service \033[1m$service\033[0m!";
    local pattern="^(.*):.*$";
    ! ( echo "$image_service" | grep -E -q "$pattern" ) && echo "$image_service" && return;
    echo "$image_service" | sed -E "s/$pattern/\1/g";
}

function get_container_patterns() {
    local pattern="$WHALES_DOCKER_CONTAINER_TEMP";
    while read service; do
        [ "$service" == "" ] && continue;
        pattern="${pattern}|${WHALES_PATH}_${service}";
    done <<< "$( docker_get_potential_services )";
    echo "^($pattern)($|_[[:digit:]]+$)";
}

##############################################################################
# AUXILIARY METHODS: DOCKER, CONTAINERS & IMAGES
##############################################################################

function docker_get_ids() {
    local args="$@";
    local part="$(    get_kwarg "$args" "part"    "" )";
    local key="$(     get_kwarg "$args" "key"     "" )";
    local pattern="$( get_kwarg "$args" "pattern" "" )";
    local lines="";

    if [   "$part" == "container" ]; then
        if [ "$key" == "" ]; then key="{{.Image}}"; fi
        local format="{{.ID}}\t$key";
        lines="$( docker ps -a --format "$format" )";
    elif [ "$part" == "image"     ]; then
        if [ "$key" == "" ]; then key="{{.Repository}}"; fi
        local format="{{.ID}}\t$key";
        lines="$( docker images -a --format "$format" )";
    fi

    while read -r line; do
        [ "$line" == "" ] && continue;
        local columns=( $line );
        local id="${columns[0]}";
        local value="${columns[1]}";
        ( echo "$value" | grep -E -q "$pattern" ) && echo "$id";
    done <<< "$lines";
}

function docker_get_id() {
    local args="$@";
    local part="$(    get_kwarg "$args" "part"    "" )";
    local key="$(     get_kwarg "$args" "key"     "" )";
    local pattern="$( get_kwarg "$args" "pattern" "" )";

    while read id; do
        [ "$id" == "" ] && continue;
        echo "$id" && return;
    done <<< "$( docker_get_ids part="$part" key="$key" pattern="$pattern" )";

    local field="$( [ "$key" == "" ] && echo "image name" || echo "$key" )";
    _log_fail "Could not find \033[1m$part\033[0m with \033[1m$field\033[0m matching /\033[93;1m$pattern\033[0m/.";
}

function docker_get_container_id_from_image_tag() {
    docker_get_id part=container key="{{.Image}}" pattern="^$1$";
}

function docker_get_image_id_from_image_tag() {
    docker_get_id part=image key="{{.Repository}}:{{.Tag}}" pattern="^$1$";
}

function docker_get_container_id_service() {
    local service="$1";
    local image_service="$( docker_get_service_image_plus_tag "$service" 2> $VERBOSE )";
    [ "$image_service" == "" ] && _log_fail "Could not find container associated to service \033[1m$service\033[0m!";
    docker_get_container_id_from_image_tag "$image_service";
}

function docker_get_image_id_service() {
    local service="$1";
    local image_service="$( docker_get_service_image_plus_tag "$service" 2> $VERBOSE )";
    [ "$image_service" == "" ] && _log_fail "Could not find image associated to service \033[1m$service\033[0m!";
    docker_get_image_id_from_image_tag "$image_service";
}

function docker_exists_image_tag() {
    [ "$1" == "" ] && return 1;
    id="$( docker_get_image_id_from_image_tag "$1" 2> $VERBOSE )";
    [ "$id" == "" ] && return 1 || return 0;
}

function docker_get_image_name_latest_stage() {
    local service="$1";
    local image="$2";
    if ! ( docker_exists_image_tag "$image" ); then
        local image_service="$( docker_get_service_image_plus_tag "$service" )";
        [ "$image_service" == "" ] && _log_fail "Could not find docker image \033[1m$image\033[0m or image for service \033[1m$service\033[0m!";
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
    docker stop "$container" && docker rm "$container";
}

function docker_remove_image() {
    local image="$1";
    docker rmi -f "$image";
}

function docker_remove_some_containers() {
    local args="$@";
    local key="$(     get_kwarg "$args" "key"     "" )";
    local pattern="$( get_kwarg "$args" "pattern" "" )";

    local found=false;
    while read id; do
        [ "$id" == "" ] && continue;
        found=true;
        docker_remove_container "$id" 2> $VERBOSE >> $VERBOSE                      \
            && _log_info  "Removed \033[1mcontainer\033[0m with id \033[1m$id\033[0m." \
            || _log_error "Could not remove \033[1mcontainer\033[0m with id \033[1m$id\033[0m.";
    done <<< "$( docker_get_ids part=container key="$key" pattern="$pattern" )";
    ! ( $found ) && _log_info "No containers were found.";
}

function docker_remove_some_images() {
    local args="$@";
    local key="$(     get_kwarg "$args" "key"     "" )";
    local pattern="$( get_kwarg "$args" "pattern" "" )";

    local found=false;
    while read id; do
        [ "$id" == "" ] && continue;
        found=true;
        docker_remove_image "$id" 2> $VERBOSE >> $VERBOSE                          \
            &&  _log_info "Removed \033[1mimage\033[0m with id \033[1m$id\033[0m." \
            || _log_error "Could not remove \033[1mimage\033[0m with id \033[1m$id\033[0m.";
    done <<< "$( docker_get_ids part=image key="$key" pattern="$pattern" )";
    ! ( $found ) && _log_info "No images were found.";
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
    if [ -f "$WHALES_FILE_DOCKER_DEPTH" ]; then
        depth="$( head -n 1 $WHALES_FILE_DOCKER_DEPTH )";
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
    export WHALES_DOCKER_SERVICE="$service";
}

function select_service_image() {
    export WHALES_DOCKER_IMAGE="$1";
}

function select_service_container_id() {
    export WHALES_DOCKER_CONTAINER="$1";
}

function set_docker_service() {
    service="$1";
    force_build=$2;
    # Force start docker servic, if not already up:
    select_service "$service";
    local image_service="$(     docker_get_service_image        "$service" 2> $VERBOSE )";
    local container_id="$( docker_get_container_id_service "$service" 2> $VERBOSE )";
    if ( $force_build ) && ( [ "$image_service" == "" ] || [ "$container_id" == "" ] ); then
        _log_info "FORCE-BUILD DOCKER SERVICE.";
        run_docker_start;
        image_service="$(     docker_get_service_image        "$service" 2> $VERBOSE )";
        container_id="$( docker_get_container_id_service "$service" 2> $VERBOSE )";
    ## else
    ## TODO: if container_id == "" but image_service =/= "", then start a container for service.
    fi
    select_service_image "$image_service";
    select_service_container_id "$container_id";
}

##############################################################################
# WHALE METHODS: "DECORATORS"
##############################################################################

####
# Checks if in docker, and either
# returns to script, or starts docker and calls script within docker.
#
# Usage:
#    call_within_docker <service> <tag-sequence> <save> <it> <expose> <script> <params>
#
# Arguments:
#    service <string>   The name of the service in whales_setup/docker-compose.yml.
#    tag-seq <string>   Comma separated sequence of tags,
#                         starting from the image-tag of the service
#                         potentially going through intermediate stages,
#                         ending with the desired image-tag to be applied when saving.
#                       ~> "tagStart" is taken to be the latest possible tag in the list,
#                          for which an image exists.
#                       ~> "tagFinal" is taken to be the final tag in the list.
#    save <bool>        Whether the created image is to be saved after creation
#                         / after interactive container containing image is exitted.
#    it <bool>          Whether the container is to be run interactive mode.
#    expose <bool>      Whether ports are to be exposed.
#    script <string>    Path to script to be carried out in docker container.
#    params <strings>   CLI params to be passed to script.
####
function call_within_docker() {
    local metaargs=( "$@" );

    ## RETURN TO SCRIPT --- if already inside docker:
    if ( is_docker ); then
        return 0;
    else
        local service="${metaargs[0]}";
        local tags="${metaargs[1]}";
        local save=${metaargs[2]};
        local it=${metaargs[3]};
        local expose=${metaargs[4]};
        local script="${metaargs[5]}";   # may not be empty.
        local params="${metaargs[@]:6}"; # may be empty.

        ## CHECK VALIDITY OF ARGUMENTS:
        [ ${#metaargs[@]} -lt 6 ] && _log_fail "In whales decorator \033[1mcall_within_docker\033[0m not enough arguments passed.";
        local regexTag="[^,]+";
        ( ( echo "$tags" | grep -E -q "[[:space:]]" ) || ! ( echo "$tags" | grep -E -q "^${regexTag}(,${regexTag})+($|,\(${regexTag}\)$)" ) ) \
            && _log_fail "In whales decorator \033[1mcall_within_docker\033[0m the \033[93;1m<tag-sequence>\033[0m argument must be a comma separated sequence of tags with no spaces and at least two elements."

        ## START/ENTER SERVICE:
        _log_info "YOU ARE OUTSIDE THE DOCKER ENVIRONMENT.";
        # Force start docker servic, if not already up:
        set_docker_service "$service" true;
        ( [ "$WHALES_DOCKER_IMAGE" == "" ] || [ "$WHALES_DOCKER_CONTAINER" == "" ] ) && _log_fail "In whales decorator \033[1mcall_within_docker\033[0m the service \033[1m$service\033[0m has not been build!";

        ## DETERMINE ENTRY + EXIT IMAGES:
        local tagParts=( ${tags//","/" "} );
        local nTags=${#tagParts[@]};
        local image_exit="";
        local image_enter="";
        local found_entry=false;
        local i=0;
        for (( i=$nTags-1; i >= 0; i-- )); do
            local tag="${tagParts[$i]}";
            if (( $i == $nTags - 1 )); then
                image_exit="$WHALES_DOCKER_IMAGE:$tag"
                ## Do not allow final tag to be a start tag, unless it is contained in parantheses:
                if ! ( echo "$tag" | grep -E -q "^\((.*)\)$" ); then continue; fi
                ## strip parantheses and proceed to test for valid entry point:
                tag="$( echo "$tag" | sed -E "s/^\((.*)\)$/\1/g" )";
                image_exit="$WHALES_DOCKER_IMAGE:$tag"
            fi
            image_enter="$WHALES_DOCKER_IMAGE:$tag";
            ( docker_exists_image_tag "$image_enter" ) && found_entry=true && break;
        done

        ! ( $found_entry ) && _log_fail "Could not find an existing image in the list \033[1m$tags\033[0m.";

        ## RUN SCRIPT COMMAND WITHIN DOCKER:
        local command=". $script $params"; # alternative: "cat $script | dos2unix | bash -s -- $params";
        if ( $save ); then
            enter_docker --service "$service" --enter "$image_enter" "$cmd_arg" --command \"$command\" --it $it --expose $expose --save "$image_exit";
        else
            enter_docker --service "$service" --enter "$image_enter" "$cmd_arg" --command \"$command\" --it $it --expose $expose;
        fi

        ## EXIT: do not return to script
        exit 0;
    fi
}

####
# This method enters a container started from an image,
# performs a command, and then saves the resulting image.
# The following relations hold/are forced between the images:
#
#                   service image == entry image ---[ after container finished ]---> save image
#       service image ---> ...  ---> entry image ---[ after container finished ]---> save image
#
# Usage:
#    enter_docker
#        --service <name> --enter <image:tag> [--save [<image:tag>]]
#        --it <bool> --expose <bool>
#        [--command <string>]
#
# Flags:
#    --service <string>      The name of the service in whales_setup/docker-compose.yml.
#    --enter <image:tag>     If argument left empty, will overwrite original.
#    [--save [<image:tag>]]  If used, will save the container to an image upon completion.
#                              (Default: coincides with --entry)
#    --it <bool>             Whether or not to run docker container interactive mode.
#      false (default)         Docker will run discretely and logs will be followed.
#    --expose <bool>         Whether or not ports are to be exposed.
#                              (Default: coincides with --it)
#    [--command <string>]    Use to start container with a command.
#                              (Default: "bash")
####
function enter_docker() {
    local metaargs="$@";
    local service="$( get_one_kwarg_space "$metaargs" "-+service" ""      )";
    local entry="$(   get_one_kwarg_space "$metaargs" "-+enter"   ""      )";
    local save_arg=false;
    ( has_arg "$metaargs" "-+save" ) && save_arg=true;
    local imageFinal="$(   get_one_kwarg_space "$metaargs" "-+save"    ""      )";
    local it=$(       get_one_kwarg_space "$metaargs" "-+it"      "false" );
    local expose=$(   get_one_kwarg_space "$metaargs" "-+expose"  ""      );
    local command="$( get_one_kwarg_space "$metaargs" "-+command" ""      )";

    _log_info "ENTER DOCKER ENVIRONMENT.";
    ## Get container of service (in order to connect mounted volumes):
    set_docker_service "$service" false;
    ( [ "$WHALES_DOCKER_IMAGE" == "" ] || [ "$WHALES_DOCKER_CONTAINER" == "" ] ) && _log_fail "In whales method \033[1menter_docker\033[0m the service \033[1m$service\033[0m has not been build!";

    ## Get image:tag for entry point:
    local entry_orig="$entry";
    if [ "$entry" == "" ]; then
        ## only if "--entry" argument is missing / empty, force the explore tag:
        entry="$WHALES_DOCKER_IMAGE:$WHALES_DOCKER_TAG_EXPLORE";
        entry_orig="$entry";
        entry="$( docker_get_image_name_latest_stage "$service" "$entry" 2> $VERBOSE )";
    fi
    ! ( docker_exists_image_tag "$entry" ) && _log_fail "In whales method \033[1menter_docker\033[0m could not find image with tag \033[1m$tag\033[0m!";

    local id="$( docker_get_image_id_from_image_tag "$entry" 2> $VERBOSE )";
    [ "$id" == "" ] && _log_fail "In whales method \033[1menter_docker\033[0m could not find image for entry point, \033[1m$entry\033[0m!";
    _log_info "CONTINUE WITH IMAGE \033[92;1m$entry\033[0m (\033[93;1m$id\033[0m).";

    ## Set arguments, if empty:
    [ "$save" == "" ] && save=false;
    [ "$command" == "" ] && command="$WHALES_DOCKER_CMD_EXPLORE" && it=true;
    [ "$expose" == "" ] && expose=$it;
    [ "$imageFinal" == "" ] && imageFinal="$entry_orig";

    ## Set ports command:
    local ports_option="$( ( $expose ) && echo "-p $WHALES_DOCKER_PORTS" || echo "" )";

    ################################
    # ENTER DOCKER: create container and run command
    local container_tmp="$( docker_create_unused_container_name )";
    _log_info "START TEMPORARY CONTAINER \033[92;1m$container_tmp\033[0m.";
    if ( $it ); then
        _log_info "EXECUTE COMMAND {\033[93;1m$command\033[0m} INTERACTIVELY.";
        docker run --name="$container_tmp" $ports_option --volumes-from=$WHALES_DOCKER_CONTAINER:rw -it $id bash -c "$command";
    else
        _log_info "EXECUTE COMMAND {\033[93;1m$command\033[0m} NON-INTERACTIVELY.";
        docker run --name="$container_tmp" $ports_option --volumes-from=$WHALES_DOCKER_CONTAINER:rw -d $id bash -c "$command";
        docker logs --follow $container_tmp;
    fi
    _log_info "WAIT FOR CONTAINER \033[92;1m$container_tmp\033[0m TO STOP.";
    wait_for_container_to_stop "$container_tmp";
    # EXIT DOCKER
    ################################

    ## Save state upon exit:
    if ( $save_arg ); then
        if [ "$imageFinal" == "$entry_orig" ]; then
            imageFinal="$entry_orig";
            _log_info "SAVE STATE TO \033[92;1m$imageFinal\033[0m (OVERWRITING).";
        else
            _log_info "SAVE STATE TO \033[92;1m$imageFinal\033[0m.";
        fi
        docker commit "$container_tmp" $imageFinal >> $VERBOSE;
    fi
    docker_remove_container "$container_tmp" 2> $VERBOSE >> $VERBOSE;
    _log_info "TEMPORARY CONTAINER \033[92;1m$container_tmp\033[0m TERMINATED.";
}

##############################################################################
# MAIN PROCESSES FOR WHALES
##############################################################################

function run_docker_start() {
    local service="$WHALES_DOCKER_SERVICE";
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
    docker_remove_some_containers key="{{.Names}}"               pattern="$( get_container_patterns )";
    docker_remove_some_images     key="{{.Repository}}:{{.Tag}}" pattern="^$WHALES_DOCKER_IMAGE:.+$";
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
