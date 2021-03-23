#!/bin/bash

##############################################################################
#    DESCRIPTION: Library of methods for Whales
#    Include using source whales_setup/.lib.whales.sh
##############################################################################

##############################################################################
# AUXILIARY METHODS: .env
##############################################################################

function env_create_local() {
    local path="$1";
    local local_env_init="${path}/docker.env";
    local local_env="${path}/.env";
    [ -f "$local_env" ] && rm "$local_env";
    cat "$local_env_init" >| "$local_env";
    echo ""                                          >> "$local_env";
    echo "WHALES_SETUP_PATH=$path"                   >> "$local_env";
    echo "WHALES_ENTRY_SCRIPT=$path/docker-entry.sh" >> "$local_env";
}

##############################################################################
# GLOBAL VARIABLES
##############################################################################

# extract from global .env file:
env_from ".env" import WHALES_SETUP_PATH                 as WHALES_PATH;
env_from ".env" import WHALES_COMPOSE_PROJECT_NAME       as WHALES_COMPOSE_PROJECT_NAME;
env_from ".env" import WHALES_DOCKER_COMPOSE_CONFIG_FILE as WHALES_DOCKER_COMPOSE_YML;
env_from ".env" import WHALES_COMPOSE_PROJECT_NAME       as WHALES_CONTAINER_SCHEME_PREFIX;

## create local .env file first:
env_create_local "$WHALES_PATH";

# extract from whales_seutp .env:
env_from "$WHALES_PATH/.env" import IP                 as WHALES_DOCKER_IP;
env_from "$WHALES_PATH/.env" import PORT_HOST          as WHALES_DOCKER_PORT_HOST;
env_from "$WHALES_PATH/.env" import PORT_CONTAINER     as WHALES_DOCKER_PORT_CONTAINER;

export WHALES_FILE_DOCKER_DEPTH="$WHALES_PATH/DOCKER_DEPTH";
export WHALES_DOCKER_PORTS="$WHALES_DOCKER_IP:$WHALES_DOCKER_PORT_HOST:$WHALES_DOCKER_PORT_CONTAINER";
export WHALES_TEMPCONTAINER_SCHEME_PREFIX="temp_$WHALES_CONTAINER_SCHEME_PREFIX";
export WHALES_DOCKER_TAG_EXPLORE="explore";
export WHALES_CONTAINER_SCHEME_PREFIX="$WHALES_COMPOSE_PROJECT_NAME";
export WHALES_DOCKER_SERVICE="";      # NOTE: This get changed dynamically.
export WHALES_IMAGE_SCHEME="";        # ""
export WHALES_DOCKER_IMAGE_NAME="";   # ""
export WHALES_DOCKER_IMAGE_TAG="";   # ""
export WHALES_DOCKER_IMAGE_ID="";     # ""
export WHALES_DOCKER_CONTAINER_ID=""; # ""

# NOTE: do not use /bin/bash. Results in error under Windows.  Use \/bin\/bash, bash, sh -c bash, or sh.
export WHALES_DOCKER_CMD_EXPLORE="bash";

##############################################################################
# AUXILIARY METHODS: DOCKER, BASIC
##############################################################################

function run_docker_compose() {
    docker-compose --project-name "$WHALES_COMPOSE_PROJECT_NAME" --file "$WHALES_DOCKER_COMPOSE_YML" $@;
}

function docker_create_unused_name() {
    local name="$1";
    k=0;
    while ( docker ps -aq --format '{{.Names}}' | grep -E -q "^${name}_${k}$" ); do k=$(( $k + 1 )); done;
    echo "${name}_${k}";
}

function docker_create_unused_container_name_for_service() {
    local service="$1"
    echo "$( docker_create_unused_name "${WHALES_CONTAINER_SCHEME_PREFIX}_${service}" )";
}

function docker_create_unused_tmpcontainer_name() {
    echo "$( docker_create_unused_name "${WHALES_TEMPCONTAINER_SCHEME_PREFIX}" )";
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
        lines="$( docker ps -aq --format "$format" )";
    elif [ "$part" == "image"     ]; then
        if [ "$key" == "" ]; then key="{{.Repository}}"; fi
        local format="{{.ID}}\t$key";
        lines="$( docker images -aq --format "$format" )";
    fi

    while read -r line; do
        [ "$line" == "" ] && continue;
        local columns=( $line );
        local id="${columns[0]}";
        local value="${columns[1]}";
        ( echo "$value" | grep -E -q "$pattern" ) && echo "$id";
    done <<< "$lines";
}

function docker_get_ids_via_inspect() {
    local args="$@";
    local part="$(   get_kwarg "$args" "part"   "" )";
    local format="$( get_kwarg "$args" "format" "" )";
    local match="$(  get_kwarg "$args" "match"  "" )";
    local lines="";

    if [ "$format" == "" ]; then format="{{.Image}}"; fi
    format="{{.Id}} $format";

    while read id; do
        [ "$id" == "" ] && continue;
        local line="$( docker inspect --format="$format" "$id" )";
        local columns=( $line );
        # local long_id="${columns[0]}"; # longer variant of container id
        local value="${columns[@]:1}";
        ( echo "$value" | grep -Eq "$match" ) && echo "$id";
    done <<< "$( docker ps -aq --format '{{.ID}}' )";
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

function docker_get_id_via_inspect() {
    local args="$@";
    local format="$( get_kwarg "$args" "format" "" )";
    local match="$(  get_kwarg "$args" "match"  "" )";

    while read id; do
        [ "$id" == "" ] && continue;
        echo "$id" && return;
    done <<< "$( docker_get_ids_via_inspect format="$format" match="$match" )";

    _log_fail "Could not find \033[1mcontainer\033[0m with \033[1m$format\033[0m matching query.";
}

function docker_get_container_id_from_image_id() {
    # DEV-NOTE: scheme in table for image_id is /sha:.*/
    docker_get_id_via_inspect part=container format="{{.Image}}" match="(^|^[^:]*:)$1";
}

function docker_get_container_id_from_image_tag() {
    docker_get_id part=container key="{{.Image}}" pattern="^$1$";
}

function docker_get_image_id_from_image_tag() {
    docker_get_id part=image key="{{.Repository}}:{{.Tag}}" pattern="^$1$";
}

function docker_exists_image_tag() {
    [ "$1" == "" ] && return 1;
    id="$( docker_get_image_id_from_image_tag "$1" 2> $VERBOSE )";
    [ "$id" == "" ] && return 1 || return 0;
}

function docker_exists_image_id() {
    local id="$1";
    [ "$id" == "" ] && return 1;
    while read line; do
        [ "$line" == "$id" ] && return 0;
    done <<< "$( docker images -aq --format '{{.ID}}' )";
    return 1;
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
    local pattern="^${WHALES_CONTAINER_SCHEME_PREFIX}_${service}($|_[[:digit:]]+$)";
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

function docker_get_service_image() {
    local service="$1";
    [ "$service" == "" ] && return;
    local pattern="^${WHALES_CONTAINER_SCHEME_PREFIX}_${service}($|_[[:digit:]]+$)";
    while read -r line; do
        local columns=( $line ); ## format: name, image, tag, image_id
        local name="${columns[0]}";
        local image="${columns[1]}";
        local tag="${columns[2]}";
        local image_id="${columns[3]}"
        ( echo "$image" | grep -Eqi "<none>" ) && image="";
        ( echo "$tag" | grep -Eqi "<none>" ) && tag="";
        ( echo "$name" | grep -Eq "$pattern" ) && echo "${image_id} ${image} ${tag}" && return;
    done <<< "$( run_docker_compose images )";
    _log_fail "Could not find any images for service \033[1m$service\033[0m!";
}

function docker_set_service_container() {
    local service="$1";
    local image_id="$WHALES_DOCKER_IMAGE_ID";
    [ "$image_id" == "" ] && _log_error "Could not find container associated to service \033[1m$service\033[0m!" && return 1;
    local container_id="$( docker_get_container_id_from_image_id "$image_id" 2> $VERBOSE )";
    [ "$container_id" == "" ] && _log_error "There is no container associated to the service \033[1m$service\033[0m." && return 1;
    export WHALES_DOCKER_CONTAINER_ID="$container_id";
}

function docker_set_service_image() {
    local service="$1";
    export WHALES_IMAGE_SCHEME="${WHALES_COMPOSE_PROJECT_NAME}_${service}";
    local output=( $( docker_get_service_image "$service" 2> $VERBOSE ) );
    local image_id="${output[0]}";
    local image="${output[1]}";
    local tag="${output[2]}";
    [ "$image_id" == "" ] && _log_error "There is no image associated to the service \033[1m$service\033[0m." && return 1;
    export WHALES_DOCKER_IMAGE_NAME="$image";
    export WHALES_DOCKER_IMAGE_TAG="$tag";
    export WHALES_DOCKER_IMAGE_ID="$image_id";
}

function get_container_pattern() {
    local pattern="$WHALES_TEMPCONTAINER_SCHEME_PREFIX";
    local service="$1";
    pattern="${pattern}|${WHALES_CONTAINER_SCHEME_PREFIX}_${service}";
    echo "^($pattern)($|_[[:digit:]]+$)";
}

function get_container_patterns() {
    local pattern="$WHALES_TEMPCONTAINER_SCHEME_PREFIX";
    while read service; do
        [ "$service" == "" ] && continue;
        pattern="${pattern}|${WHALES_CONTAINER_SCHEME_PREFIX}_${service}";
    done <<< "$( docker_get_potential_services )";
    echo "^($pattern)($|_[[:digit:]]+$)";
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
        docker_remove_container "$id" 2> $VERBOSE >> $VERBOSE                          \
            && _log_info  "Removed \033[1mcontainer\033[0m with id \033[1m$id\033[0m." \
            || _log_error "Could not remove \033[1mcontainer\033[0m with id \033[1m$id\033[0m.";
    done <<< "$( docker_get_ids part=container key="$key" pattern="$pattern" )";
    ! ( $found ) && _log_error "No containers were found.";
}

function docker_remove_some_images() {
    local args="$@";
    local key="$(     get_kwarg "$args" "key"     "" )";
    local pattern="$( get_kwarg "$args" "pattern" "" )";

    local found=false;
    while read id; do
        [ "$id" == "" ] && continue;
        found=true;
        docker_remove_image "$id" 2> $VERBOSE >> $VERBOSE                         \
            && _log_info "Removed \033[1mimage\033[0m with id \033[1m$id\033[0m." \
            || _log_error "Could not remove \033[1mimage\033[0m with id \033[1m$id\033[0m.";
    done <<< "$( docker_get_ids part=image key="$key" pattern="$pattern" )";
    ! ( $found ) && _log_error "No images were found.";
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
    done <<< "$( docker ps -aq --format '{{.ID}}\t{{.Names}}\t{{.Image}}' )";
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
    done <<< "$( docker images -aq --format '{{.ID}}\t{{.Repository}}\t{{.Tag}}' )";
}

##############################################################################
# AUXILIARY METHODS: DOCKER DEPTH
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

##############################################################################
# MAIN METHODS: GET/SET SERVICES, ENTER DOCKER
##############################################################################

function get_service_image_name() {
    local name="$WHALES_DOCKER_IMAGE_NAME";
    [ "$name" == "" ] && echo "$WHALES_IMAGE_SCHEME" || echo "$name";
}

function get_service_image_name_plus_tag() {
    local name="$WHALES_DOCKER_IMAGE_NAME";
    local tag="$WHALES_DOCKER_IMAGE_TAG";
    [ "$name" == "" ] && echo "$WHALES_IMAGE_SCHEME" || echo "$name:$tag";
}

function get_service_image_name_plus_tag_or_id() {
    local name="$WHALES_DOCKER_IMAGE_NAME";
    local tag="$WHALES_DOCKER_IMAGE_TAG";
    [ "$name" == "" ] && echo "$WHALES_DOCKER_IMAGE_ID" || echo "$name:$tag";
}

function select_service() {
    local service="$1";
    ! ( docker_exists_potential_service "$service" ) \
        && _log_error "There is no valid definition for \033[1m$service\033[0m in \033[1m$WHALES_DOCKER_COMPOSE_YML\033[0m!" \
        && return 1;
    local success=true;
    export WHALES_DOCKER_SERVICE="$service";
    docker_set_service_image "$service" || success=false;
    docker_set_service_container "$service" || success=false;
    ( $success ) && return 0 || return 1;
}

function get_docker_service() {
    local service="$1";
    local force_build=$2;
    [ "$force_build" == "" ] && force_build=false;
    local success;

    # Attempt to set service
    select_service "$service" 2> $VERBOSE >> $VERBOSE && success=true || success=false;
    ( $success ) && return 0;
    ! ( $force_build ) && _log_error "Could not set the service to \033[1m$service\033[0m." && return 1;

    # Force start docker servic, if not already up:
    _log_info "FORCE-BUILD DOCKER SERVICE.";
    _log_info "START DOCKER SERVICE \033[92;1m$service\033[0m.";
    # Call docker-compose:
    local lines="$( run_docker_compose up --build "$service" )";

    # After completion, scan output lines for information about image id:
    local pattern="^[[:space:]]*successfully built[[:space:]]*([^[:space:]]+)";
    success=false;
    while read line; do
        line="$( to_lower "$line" )";
        if ( echo "$line" | grep -Eq "$pattern" ); then
            # extract image id, then used docker inspect + docker ps, to find container id:
            image_id="$( echo "$line" | sed -E "s/$pattern/\1/g" )";
            container_id="$( docker_get_container_id_from_image_id "$image_id" 2> $VERBOSE )";
            success=true;
            break;
        fi
    done <<< "$lines";
    ! ( $success ) && _log_error "Could not build service \033[1m$service\033[0m!" && return 1;

    # Rename container to Whales scheme (see .env in setup folder):
    local container_name="$( docker_create_unused_container_name_for_service "$service" )";
    _log_info "RENAME CONTAINER \033[1m$container_id\033[0m ---> \033[92;1m$container_name\033[0m.";
    docker rename "$container_id" "$container_name";

    # Attempt to set service again:
    # DEV-NOTE: For some reason the `select_service` command results return 1, unless split up lie this.
    select_service "$service" 2> $VERBOSE >> $VERBOSE && success=true || success=false;
    ! ( $success ) && _log_error "Could not set the service to \033[1m$service\033[0m." && return 1;
    return 0;
}

####
# This method starts container from a specified image,
# performs a command, and then saves to a specified image.
# The following relations hold/are forced between the images:
#
#    service image
#    \____> ...
#             \____> entry image (or == service image)
#                  \
#      [ after container finished ]
#                   \________> save image
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
    local service="$(    get_one_kwarg_space "$metaargs" "-+service" ""      )";
    local entry="$(      get_one_kwarg_space "$metaargs" "-+enter"   ""      )";
    local save_arg=false;
    ( has_arg "$metaargs" "-+save" ) && save_arg=true;
    local imageFinal="$( get_one_kwarg_space "$metaargs" "-+save"    ""      )";
    local it=$(          get_one_kwarg_space "$metaargs" "-+it"      "false" );
    local expose=$(      get_one_kwarg_space "$metaargs" "-+expose"  ""      );
    local command="$(    get_one_kwarg_space "$metaargs" "-+command" ""      )";

    _log_info "ENTER DOCKER ENVIRONMENT.";
    ## Get container of service (in order to connect mounted volumes):
    # DEV-NOTE: Do not enclose in ( ... ) here, otherwise exports do not work.
    get_docker_service "$service" false 2> $VERBOSE >> $VERBOSE \
        || _log_fail "In whales decorator \033[1menter_docker\033[0m the service \033[93;1m$service\033[0m could not be found.";

    ## Get image:tag for entry point:
    local entry_orig="$entry";
    if [ "$entry" == "" ]; then
        ## only if "--entry" argument is missing / empty, force the explore tag:
        entry="$WHALES_DOCKER_IMAGE_NAME:$WHALES_DOCKER_TAG_EXPLORE";
        entry_orig="$entry";
        entry="$( docker_get_image_name_latest_stage "$service" "$entry" 2> $VERBOSE )";
        ! ( docker_exists_image_tag "$entry" ) && entry="$( get_service_image_name_plus_tag_or_id )";
    else
        ! ( docker_exists_image_tag "$entry" ) && _log_fail "In whales method \033[1menter_docker\033[0m could not find image \033[1m$entry\033[0m!";
    fi

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
    local container_tmp="$( docker_create_unused_tmpcontainer_name )";
    _log_info "START TEMPORARY CONTAINER \033[92;1m$container_tmp\033[0m.";
    if ( $it ); then
        _log_info "EXECUTE COMMAND {\033[93;1m$command\033[0m} INTERACTIVELY.";
        docker run --name="$container_tmp" $ports_option --volumes-from=$WHALES_DOCKER_CONTAINER_ID:rw -it $id bash -c "$command";
    else
        _log_info "EXECUTE COMMAND {\033[93;1m$command\033[0m} NON-INTERACTIVELY.";
        docker run --name="$container_tmp" $ports_option --volumes-from=$WHALES_DOCKER_CONTAINER_ID:rw -d $id bash -c "$command";
        docker logs --follow $container_tmp;
    fi
    _log_info "WAIT FOR CONTAINER \033[92;1m$container_tmp\033[0m TO STOP.";
    _log_info "TEMPORARY CONTAINER \033[92;1m$container_tmp\033[0m TERMINATED.";
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
    _log_info "TEMPORARY CONTAINER \033[92;1m$container_tmp\033[0m REMOVED.";
}
