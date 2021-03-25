#!/bin/bash

##############################################################################
#    DESCRIPTION: Library of methods for Whales
#    Include using source whales_setup/.lib.whales.sh
##############################################################################

##############################################################################
# AUXILIARY METHODS: .env
##############################################################################

function env_create_local() {
    local path="$WHALES_SETUP_PATH";
    local project="$WHALES_PROJECT_NAME";
    local service="$WHALES_DOCKER_SERVICE";
    local local_env_init="${path}/docker.env";
    local local_env="${path}/.env";
    [ -f "$local_env" ] && rm "$local_env";
    touch "$local_env";
    echo "# environment variables from setup folder:"   >> "$local_env";
    cat  "$local_env_init"                              >> "$local_env";
    echo ""                                             >> "$local_env";
    echo "# environment variables from project source:" >> "$local_env";
    echo "WHALES_SETUP_PATH=$path"                      >> "$local_env";
    echo "WHALES_ENTRY_SCRIPT=$path/docker-entry.sh"    >> "$local_env";
    echo "WHALES_PROJECT_NAME=$project"                 >> "$local_env";
    echo ""                                             >> "$local_env";
    echo "# tmp environment variables for service:"     >> "$local_env";
    echo "WHALES_SELECTED_SERVICE=$service"             >> "$local_env";
}

##############################################################################
# GLOBAL VARIABLES
##############################################################################

# extract from global .env file:
env_from "whales.env" import WHALES_SETUP_PATH;
env_from "whales.env" import WHALES_PROJECT_NAME;

## create local .env file first:
env_create_local;

# extract from whales_seutp .env:
env_from "$WHALES_SETUP_PATH/.env" import IP                 as WHALES_DOCKER_IP;
env_from "$WHALES_SETUP_PATH/.env" import PORT_HOST          as WHALES_DOCKER_PORT_HOST;
env_from "$WHALES_SETUP_PATH/.env" import PORT_CONTAINER     as WHALES_DOCKER_PORT_CONTAINER;

export WHALES_DOCKER_COMPOSE_YML="${WHALES_SETUP_PATH}/docker-compose.yml";
export WHALES_FILE_DOCKER_DEPTH="$WHALES_SETUP_PATH/DOCKER_DEPTH";
export WHALES_DOCKER_PORTS="$WHALES_DOCKER_IP:$WHALES_DOCKER_PORT_HOST:$WHALES_DOCKER_PORT_CONTAINER";
export WHALES_TEMPCONTAINER_SCHEME_PREFIX="temp_${WHALES_PROJECT_NAME}";
export WHALES_DOCKER_TAG_EXPLORE="explore";
export WHALES_DOCKER_SERVICE="";      # NOTE: This get changed dynamically.
export WHALES_DOCKER_IMAGE_NAME="";   # ""
export WHALES_DOCKER_IMAGE_ID="";     # ""
export WHALES_DOCKER_CONTAINER_ID=""; # ""

# NOTE: do not use /bin/bash. Results in error under Windows.  Use \/bin\/bash, bash, sh -c bash, or sh.
export WHALES_DOCKER_CMD_EXPLORE="bash";

##############################################################################
# AUXILIARY METHODS: BASIC
##############################################################################

function run_docker_compose() {
    docker-compose --project-name "$WHALES_PROJECT_NAME" --file "$WHALES_DOCKER_COMPOSE_YML" $@;
}

function docker_create_unused_name() {
    local name="$1";
    k=0;
    while ( docker ps -aq --format '{{.Names}}' | grep -Eq "^${name}_${k}$" ); do k=$(( $k + 1 )); done;
    echo "${name}_${k}";
}

function docker_create_unused_container_name_for_service() {
    local service="$1"
    echo "$( docker_create_unused_name "${WHALES_PROJECT_NAME}_${service}" )";
}

function docker_create_unused_tmpcontainer_name() {
    echo "$( docker_create_unused_name "${WHALES_TEMPCONTAINER_SCHEME_PREFIX}" )";
}

##############################################################################
# AUXILIARY METHODS: MISC
##############################################################################

function get_tag_from_image_name() {
    local value="$1";
    local pattern="^.*:([^:]*)$";
    ! ( echo "$value" | grep -Eq "$pattern" ) && echo "<none>" && return;
    echo "$( echo "$1" | sed -E "s/$pattern/\1/g" )";
}

##############################################################################
# AUXILIARY METHODS: SERVICES, CONTAINERS, IMAGES
##############################################################################

function docker_get_service_image_ids() {
    local project="$1";
    local service="$2";
    local format="{{.ID}}";
    local filters="";
    ! [ "$project" == "" ] && filters="$filters --filter label=org.whales.project=$project";
    ! [ "$service" == "" ] && filters="$filters --filter label=org.whales.service=$service";
    docker images -aq --format "$format" $filters;
}

function docker_get_service_container_ids() {
    local project="$1";
    local service="$2";
    local format="{{.ID}}";
    local filters="";
    ! [ "$project" == "" ] && filters="$filters --filter label=org.whales.project=$project";
    ! [ "$service" == "" ] && filters="$filters --filter label=org.whales.service=$service";
    docker ps -aq --format "$format" $filters;
}

function docker_get_container_id_from_image_id() {
    local image_id="$1";
    local format="{{.Image}}"; # <- DEV-NOTE: scheme in table for image_id is /sha:.*/
    local pattern="(^|^[^:]*:)$image_id";
    while read line; do
        line="$( _trim "$line" )";
        [ "$line" == "" ] && continue;
        local container_id="$line";
        local value="$( docker inspect --format="$format" "$container_id" )";
        ( echo "$value" | grep -Eq "$pattern" ) && echo "$container_id" && return;
    done <<< "$( docker ps -aq --format '{{.ID}}' )";
    _log_fail "Could not find \033[1mcontainer\033[0m for image_id \033[93;1m$image_id\033[0m.";
}

function docker_get_service_image_from_tag() {
    local init=$1;
    local project="$WHALES_PROJECT_NAME";
    local service="$2";
    local value="$3";
    local format="{{.ID}}\t{{.Repository}}\t{{.Tag}}";
    local filters="--filter label=org.whales.project=$project --filter label=org.whales.service=$service";
    if ( $init ); then
        filters="$filters --filter label=org.whales.initial=true";
    else
        filters="$filters --filter label=org.whales.tag=$value";
    fi
    local lines="$( docker images -aq --format "$format" $filters )";
    while read line; do
        line="$( _trim "$line" )";
        [ "$line" == "" ] && continue;
        local columns=( $line );
        local image_id="${columns[0]}";
        local image="${columns[1]}";
        local tag="${columns[2]}";
        ( echo "$image:$tag" | grep -Eiq "<none>" ) && echo "$image_id" || echo "$image_id $image $tag";
        return;
    done <<< "$lines";
    if ( $init ); then
        _log_fail "Could not find initial image of service \033[1m$service\033[0m!";
    else
        _log_fail "Could not find image with tag \033[1m$value\033[0m for service \033[1m$service\033[0m!";
    fi
}

function docker_exists_service_tag() {
    local service="$1";
    local value="$2";
    local init=false;
    [ "$value" == "." ] && init=true;
    [ "$value" == "" ] && return 1;
    local output=( $( docker_get_service_image_from_tag $init "$service" "$value" 2> $VERBOSE ) );
    local image_id="${output[0]}";
    [ "$image_id" == "" ] && return 1 || return 0;
}

function docker_set_service_image() {
    local project="$WHALES_PROJECT_NAME";
    local service="$1";
    local output=( $( docker_get_service_image_from_tag true "$service" "." 2> $VERBOSE ) );
    local image_id="${output[0]}";
    local image="${output[1]}";
    [ "$image_id" == "" ] && _log_error "There is no image associated to the service \033[1m$service\033[0m." && return 1;
    [ "$image" == "" ] && name="${project}_${service}"
    export WHALES_DOCKER_IMAGE_NAME="$image";
    export WHALES_DOCKER_IMAGE_ID="$image_id";
}

function docker_set_service_container() {
    local project="$WHALES_PROJECT_NAME";
    local service="$1";
    local image_id="$WHALES_DOCKER_IMAGE_ID";
    [ "$image_id" == "" ] && _log_error "Could not find container associated to service \033[1m$service\033[0m!" && return 1;
    local container_id="$( docker_get_container_id_from_image_id "$image_id" 2> $VERBOSE )";
    [ "$container_id" == "" ] && _log_error "There is no container associated to the service \033[1m$service\033[0m." && return 1;
    export WHALES_DOCKER_CONTAINER_ID="$container_id";
}

function docker_get_start_and_end_points() {
    local service="$1";
    local tags="$2";

    ## preformat the sequences of tags:
    # strip spaces:
    tags="$( echo "$tags" | sed -E s/[[:space:]]//g )";
    # for sequences "tag_1" of length one, replace by "tag_1,tag_1"
    ! ( echo "$tags" | grep -Eq "," ) && tags="$tags,$tags";
    # replace sequences of the form ",tag_1,...,tag_n" by ".,tag_1,...,tag_n"
    tags="$( echo "$tags" | sed -E "s/^,(.*)/.,\1/" )";
    # replace sequences "tag1_,tag_2,...,(tag_n)" by "tag1_,tag_2,...,tag_n"
    tags="$( echo "$tags" | sed -E "s/(^|^.*),\((.*)\)$/\1,\2,\2/g" )";

    local tagParts=( ${tags//","/" "} );
    local nTags=${#tagParts[@]};
    local tagStart="";
    local tagFinal="";
    local i=0;
    for (( i=$nTags-1; i >= 0; i-- )); do
        local tag="${tagParts[$i]}";
        # Do not allow position n-1 to be used as a start tag:
        (( $i == $nTags - 1 )) && tagFinal="$tag" && continue;
        # If tag exists as entry point, then stop search:
        ( docker_exists_service_tag "$service" "$tag" ) && echo "$tag $tagFinal" && return;
    done
    _log_fail "Could not find a starting point.";
}

##############################################################################
# AUXILIARY METHODS: STATE
##############################################################################

function docker_is_container_stopped() {
    local id="$1";
    container_is_running="$( docker container inspect --format '{{.State.Running}}' $id 2> $VERBOSE || echo "" )";
    container_state="$(      docker container inspect --format '{{.State.Status}}'  $id 2> $VERBOSE || echo "" )";
    ## if empty status, then container does not exist --> "stopped":
    if [ "$container_is_running" == "" ] && [ "$container_state" == "" ]; then return 0; fi
    ## else check values:
    [ "$container_is_running" == "false" ] && return 0 || return 1;
    [ "$container_state" == "exited" ] && return 0 || return 1;
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

function docker_show_some_containers() {
    local show_labels=$1;
    local project="$2";
    local service="$3";
    local filters="";
    ! [ "$project" == "" ] && filters="$filters --filter label=org.whales.project=$project";
    ! [ "$service" == "" ] && filters="$filters --filter label=org.whales.service=$service";
    local format="table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Size}}\t{{.Status}}\t{{.CreatedAt}}";
    if ( $show_labels ); then
        local lines="$( docker ps -aq --format "$format" $filters )";
        local first_line=true;
        while read line; do
            line="$( _trim "$line" )";
            ( $first_line ) && echo -e "$line" && first_line=false && continue;
            local parts=( $line );
            local id="${parts[0]}";
            local labels="$( docker inspect --format '{{ json .Config.Labels }}' "$id" )";
            _cli_message "$line\n     labels:   $labels";
        done <<< "$lines";
    else
        docker ps -aq --format "$format" $filters;
    fi
}

function docker_show_some_images() {
    local show_labels=$1;
    local project="$2";
    local service="$3";
    local filters="";
    ! [ "$project" == "" ] && filters="$filters --filter label=org.whales.project=$project";
    ! [ "$service" == "" ] && filters="$filters --filter label=org.whales.service=$service";
    local format="table {{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    if ( $show_labels ); then
        local lines="$( docker images -aq --format "$format" $filters )";
        local first_line=true;
        while read line; do
            line="$( _trim "$line" )";
            ( $first_line ) && echo -e "$line" && first_line=false && continue;
            local parts=( $line );
            local id="${parts[0]}";
            local labels="$( docker inspect --format '{{ json .Config.Labels }}' "$id" )";
            _cli_message "\n$line\n     labels:   $labels";
        done <<< "$lines";
    else
        docker images -aq --format "$format" $filters;
    fi
}

##############################################################################
# AUXILIARY METHODS: CLEANING
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
    local project="$1";
    local service="$2";
    local filters="";
    ! [ "$project" == "" ] && filters="$filters --filter label=org.whales.project=$project";
    ! [ "$service" == "" ] && filters="$filters --filter label=org.whales.service=$service";
    local format="{{.ID}}";
    local lines="$( docker ps -aq --format "$format" $filters )";
    while read line; do
        line="$( _trim "$line" )";
        [ "$line" == "" ] && continue;
        found=true;
        id="$line";
        docker_remove_container "$id" 2> $VERBOSE >> $VERBOSE \
            && _cli_message "Removed \033[1mcontainer\033[0m with id {\033[1m$id\033[0m}." \
            || _log_error "Could not remove \033[1mcontainer\033[0m with id {\033[1m$id\033[0m}.";
    done <<< "$lines";
    ! ( $found ) && _log_info "No containers were found.";

}

function docker_remove_some_images() {
    local project="$1";
    local service="$2";
    local filters="";
    ! [ "$project" == "" ] && filters="$filters --filter label=org.whales.project=$project";
    ! [ "$service" == "" ] && filters="$filters --filter label=org.whales.service=$service";
    local format="{{.ID}}";
    local lines="$( docker images -aq --format "$format" $filters )";
    local found=false;
    while read line; do
        line="$( _trim "$line" )";
        [ "$line" == "" ] && continue;
        found=true;
        id="$line";
        docker_remove_image "$id" 2> $VERBOSE >> $VERBOSE \
            && _cli_message "Removed \033[1mimage\033[0m with id {\033[1m$id\033[0m}." \
            || _log_error "Could not remove \033[1mimage\033[0m with id {\033[1m$id\033[0m}.";
    done <<< "$lines";
    ! ( $found ) && _log_info "No images were found.";
}

function docker_remove_all_containers() {
    while read line; do
        line="$( _trim "$line" )";
        if [ "$line" == "" ]; then continue; fi
        local columns=( $line );
        local id="${columns[0]}";
        local names="${columns[1]}";
        local image="${columns[2]}";
        _cli_message "- \033[91mremove\033[0m container $names ($id) ---> has image $image";
        docker stop "$id" && docker rm "$id" 2> $VERBOSE;
    done <<< "$( docker ps -aq --format '{{.ID}}\t{{.Names}}\t{{.Image}}' )";
}

function docker_remove_all_images() {
    while read line; do
        line="$( _trim "$line" )";
        if [ "$line" == "" ]; then continue; fi
        local columns=( $line );
        local id="${columns[0]}";
        local image="${columns[1]}";
        local tag="${columns[2]}";
        _cli_message "- \033[91mremove\033[0m image $image:$tag ($id)";
        docker rmi -f "$id" 2> $VERBOSE;
    done <<< "$( docker images -aq --format '{{.ID}}\t{{.Repository}}\t{{.Tag}}' )";
}

##############################################################################
# AUXILIARY METHODS: DEPTH
##############################################################################

function get_docker_depth() {
    local depth=0;
    if [ -f "$WHALES_FILE_DOCKER_DEPTH" ]; then
        depth="$( head -n 1 $WHALES_FILE_DOCKER_DEPTH )";
        if ! ( echo "$depth" | grep -Eq "^(0|[1-9][0-9]*|-[1-9][0-9]*)$" ); then depth=1; fi
    fi
    echo $depth;
}

function is_docker() {
    local depth=$( get_docker_depth );
    [ $depth -gt 0 ] && return 0 || return 1;
}

##############################################################################
# AUXILIARY METHODS: GET/SET SERVICES
##############################################################################

function select_service() {
    local service="$1";
    local success=true;
    export WHALES_DOCKER_SERVICE="$service";
    env_create_local; # <- Update .env due to choice of service.
    docker_set_service_image     "$service" || success=false;
    docker_set_service_container "$service" || success=false;
    ( $success ) && return 0 || return 1;
}

function get_docker_service() {
    local project="$WHALES_PROJECT_NAME";
    local service="$1";
    local force_build=$2;
    [ "$force_build" == "" ] && force_build=false;
    local success;

    # Attempt to set service
    select_service "$service" 2> $VERBOSE && success=true || success=false;
    ( $success ) && return 0;
    ! ( $force_build ) && _log_error "Could not set the service to \033[1m$service\033[0m." && return 1;

    # Force start docker servic, if not already up:
    _log_info "FORCE-BUILD DOCKER SERVICE.";
    _log_info "START DOCKER SERVICE \033[92;1m$service\033[0m.";
    run_docker_compose up --build "$service";

    # Attempt to set service again:
    select_service "$service" 2> $VERBOSE && success=true || success=false;
    ! ( $success ) && _log_error "Could not set the service to \033[1m$service\033[0m." && return 1;

    # Rename container to Whales scheme (see .env in setup folder):
    local container_id="${WHALES_DOCKER_CONTAINER_ID}";
    local container_name="$( docker_create_unused_container_name_for_service "$service" )";
    _log_info "RENAME CONTAINER \033[1m$container_id\033[0m ---> \033[92;1m$container_name\033[0m.";
    docker rename "$container_id" "$container_name";
    return 0;
}

##############################################################################
# MAIN METHODS: CALL-DECORATOR, ENTER DOCKER
##############################################################################

####
# Checks if in docker, and either
# returns to script, or starts docker and calls script within docker.
#
# Usage:
#    call_within_docker <service> <tag-sequence> <save> <it> <expose> [<script> <params>]
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
#  Optional:
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
        local script="${metaargs[5]}"; # may be empty.
        local params="${metaargs[@]:6}"; # may be empty.

        ## CHECK VALIDITY OF ARGUMENTS:
        [ ${#metaargs[@]} -lt 5 ] && _log_fail "In whales decorator \033[1mcall_within_docker\033[0m not enough arguments passed.";

        ## CREATE SERVICE:
        _log_info "YOU ARE OUTSIDE THE DOCKER ENVIRONMENT.";
        # Force start docker servic, if not already up:
        # DEV-NOTE: Do not enclose in ( ... ) here, otherwise exports do not work.
        get_docker_service "$service" true \
            || _log_fail "In whales decorator \033[1mcall_within_docker\033[0m the service \033[93;1m$service\033[0m could not be found or created.";

        ## DETERMINE ENTRY + EXIT IMAGES:
        local output=( $( docker_get_start_and_end_points "$service" "$tags" 2> $VERBOSE ) );
        local tagStart="${output[0]}";
        local tagFinal="${output[1]}";
        [ "$tagStart" == "" ] && _log_fail "Could not find an existing image with one of the tags in \033[1m$tags\033[0m for the service \033[1m$service\033[0m.";

        ## RUN SCRIPT COMMAND WITHIN DOCKER:
        local save_arg="";
        ( $save ) && save_arg="--save \"$tagFinal\"";
        local cmd_arg="";
        ! [ $script == "" ] && cmd_arg="--command \"source $script $params\"";
        # alternative: "--command \"cat $script | dos2unix | bash -s -- $params\"";
        enter_docker --service "$service" --enter "$tagStart" $save_arg --it $it --expose $expose $cmd_arg;

        ## EXIT: Do not return to script!
        exit 0;
    fi
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
#        --service <name> --enter <tag> [--save [<tag>]]
#        --it <bool> --expose <bool>
#        [--command <string>]
#
# Flags:
#    --service <string>      The name of the service in whales_setup/docker-compose.yml.
#    --enter   <tag>         If argument left empty, will overwrite original.
#    [--save  [<tag>]]       If used, will save the container to an image upon completion.
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
    local service="$(  get_one_kwarg_space "$metaargs" "-+service" ""      )";
    local tagStart="$( get_one_kwarg_space "$metaargs" "-+enter"   "."     )";
    local save_arg=false;
    ( has_arg "$metaargs" "-+save" ) && save_arg=true;
    local tagFinal="$( get_one_kwarg_space "$metaargs" "-+save"    ""      )";
    local it=$(        get_one_kwarg_space "$metaargs" "-+it"      "false" );
    local expose=$(    get_one_kwarg_space "$metaargs" "-+expose"  ""      );
    local command="$(  get_one_kwarg_space "$metaargs" "-+command" ""      )";
    local command_descr="####"; # <- censore description of command.

    _log_info "ENTER DOCKER ENVIRONMENT.";
    ## Get container of service (in order to connect mounted volumes):
    # DEV-NOTE: Do not enclose in ( ... ) here, otherwise exports do not work.
    get_docker_service "$service" false 2> $VERBOSE >> $VERBOSE \
        || _log_fail "In whales decorator \033[1menter_docker\033[0m the service \033[93;1m$service\033[0m could not be found.";

    ## Get image:tag for entry point:
    local init=false;
    [ "$tagStart" == "." ] && init=true;
    [ "$tagStart" == "" ] && return 1;
    local output=( $( docker_get_service_image_from_tag $init "$service" "$tagStart" 2> $VERBOSE ) );
    local image_id="${output[0]}";
    [ "$image_id" == "" ] && _log_fail "In whales method \033[1menter_docker\033[0m could not find image with tag \033[1m$tagStart\033[0m for service \033[93;1m$service\033[0m!";

    _log_info "CONTINUE WITH IMAGE \033[1m$tagStart\033[0m (\033[93;1m$image_id\033[0m).";

    ## Set arguments, if empty:
    [ "$save" == "" ] && save=false;
    [ "$command" == "" ] && command="$WHALES_DOCKER_CMD_EXPLORE" && it=true;
    [ "$expose" == "" ] && expose=$it;
    [ "$tagFinal" == "" ] && tagFinal="$tagStart";

    ## Set ports command:
    local ports_option="$( ( $expose ) && echo "-p $WHALES_DOCKER_PORTS" || echo "" )";

    ################################
    # ENTER DOCKER: create container and run command
    local container_tmp="$( docker_create_unused_tmpcontainer_name )";
    _log_info "START TEMPORARY CONTAINER \033[92;1m$container_tmp\033[0m.";
    if ( $it ); then
        _log_info "EXECUTE COMMAND {\033[93;1m$command_descr\033[0m} INTERACTIVELY.";
        docker run --name="$container_tmp" $ports_option --volumes-from=$WHALES_DOCKER_CONTAINER_ID:rw \
            --label org.whales.project="$WHALES_PROJECT_NAME" \
            --label org.whales.service="$service"             \
            --label org.whales.tag="$tagFinal"                \
            --label org.whales.initial=false                  \
            -it $image_id bash -c "$command";
    else
        _log_info "EXECUTE COMMAND {\033[93;1m$command_descr\033[0m} NON-INTERACTIVELY.";
        docker run --name="$container_tmp" $ports_option --volumes-from=$WHALES_DOCKER_CONTAINER_ID:rw \
            --label org.whales.project="$WHALES_PROJECT_NAME" \
            --label org.whales.service="$service"             \
            --label org.whales.tag="$tagFinal"                \
            --label org.whales.initial=false                  \
            -d $image_id bash -c "$command";
        docker logs --follow $container_tmp;
    fi
    _log_info "WAIT FOR CONTAINER \033[92;1m$container_tmp\033[0m TO STOP.";
    _log_info "TEMPORARY CONTAINER \033[92;1m$container_tmp\033[0m TERMINATED.";
    wait_for_container_to_stop "$container_tmp";
    # EXIT DOCKER
    ################################

    ## Save state upon exit:
    if ( $save_arg ); then
        if [ "$tagFinal" == "$tagStart" ]; then
            _log_info "SAVE STATE TO \033[92;1m$tagFinal\033[0m (OVERWRITES TAGS).";
        else
            _log_info "SAVE STATE TO \033[92;1m$tagFinal\033[0m.";
        fi
        docker commit "$container_tmp" $WHALES_DOCKER_IMAGE_NAME:$tagFinal >> $VERBOSE;
    fi
    docker_remove_container "$container_tmp" 2> $VERBOSE >> $VERBOSE;
    _log_info "TEMPORARY CONTAINER \033[92;1m$container_tmp\033[0m REMOVED.";
}
