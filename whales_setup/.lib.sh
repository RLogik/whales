#!/bin/bash

##############################################################################
#    DESCRIPTION: Library of methods for Whales
#    Include using source whales_setup/.lib.sh
##############################################################################

source whales_setup/.lib.globals.sh;
source whales_setup/.lib.utils.sh;
source whales_setup/.lib.whales.sh;

##############################################################################
# WHALES METHODS: "DECORATORS"
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
        local tags_orig="$tags";
        local regexTag="[^,]+";
        local pattern1="(^|^.*),\((.*)\)$";
        local pattern2="^${regexTag}(,${regexTag})+";
        ! ( echo "$tags" | grep -E -q "," ) && tags="$tags,$tags"; # for sequences of length one, replace by "tag1,tag1"
        ( echo "$tags" | grep -E -q "$pattern1" ) && tags="$( echo "$tags" | sed -E "s/$pattern1/\1,\2,\2/g" )";
        ( ( echo "$tags" | grep -E -q "[[:space:]]" ) || ! ( echo "$tags" | grep -E -q "$pattern2" ) ) \
            && _log_fail "In whales decorator \033[1mcall_within_docker\033[0m the \033[93;1m<tag-sequence>\033[0m argument must be a comma separated sequence of tags with no spaces. You entered \033[91;m$tags_orig\033[0m."

        ## CREATE SERVICE:
        _log_info "YOU ARE OUTSIDE THE DOCKER ENVIRONMENT.";
        # Force start docker servic, if not already up:
        # DEV-NOTE: Do not enclose in ( ... ) here, otherwise exports do not work.
        get_docker_service "$service" true \
            || _log_fail "In whales decorator \033[1mcall_within_docker\033[0m the service \033[93;1m$service\033[0m could not be found or created.";

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

        ! ( $found_entry ) && _log_fail "Could not find an existing image in the list \033[1m$tags_orig\033[0m.";

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
    # DEV-NOTE: Do not enclose in ( ... ) here, otherwise exports do not work.
    get_docker_service "$service" false 2> $VERBOSE >> $VERBOSE \
        || _log_fail "In whales decorator \033[1mcall_within_docker\033[0m the service \033[93;1m$service\033[0m could not be found.";

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
    local container_tmp="$( docker_create_unused_tmpcontainer_name )";
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
    run_docker_compose up --build $service || _log_fail "Usage of docker-compose resulted in failure.";
}

function run_docker_stop_down() {
    run_docker_compose stop;
    run_docker_compose down;
}

function run_docker_clean() {
    docker_remove_some_containers key="{{.Names}}"               pattern="$( get_container_pattern "$WHALES_DOCKER_SERVICE" )";
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
    _cli_message "\033[94;1mSERVICES\033[0m:";
    run_docker_compose ps -a;
    _cli_message "";
    run_docker_compose images;
    _cli_message "";
    _cli_message "\033[94;1mCONTAINERS\033[0m:";
    docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Size}}\t{{.Status}}\t{{.CreatedAt}} ago';
    _cli_message "";
    _cli_message "\033[94;1mIMAGES\033[0m:";
    docker images -a --format 'table {{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}';
    _cli_message "";
}

function run_docker_enter() {
    local service="$1";
    local tag="$2";
    image="$( docker_get_service_image "$service" )";
    _log_info "ATTEMPTING TO ENTER \033[1m$image:$tag\033[0m.";
    enter_docker --service "$service" --enter "$image:$tag" --it true;
}
