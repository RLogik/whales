#!/bin/bash

##############################################################################
#    DESCRIPTION: Library of methods for Whales
#    Include using source whales_setup/.lib.meta.sh
##############################################################################

##############################################################################
# DECORATOR: whale_call
##############################################################################

####
# Checks if in docker, and either
# returns to script, or starts docker and calls script within docker.
#
# Usage:
#    whale_call <service> <tag-sequence> <save> <it> <expose> [<script> <params>]
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
function whale_call() {
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
        local comand="${metaargs[@]:5}";

        ## CHECK VALIDITY OF ARGUMENTS:
        [ ${#metaargs[@]} -lt 5 ] && _log_fail "In whales decorator \033[1mcall_within_docker\033[0m not enough arguments passed.";

        ## CREATE SERVICE:
        _log_info "YOU ARE OUTSIDE THE DOCKER ENVIRONMENT.";
        # Force start docker servic, if not already up:
        # DEV-NOTE: Do not enclose in ( ... ) here, otherwise exports do not work.
        get_docker_service "$service" true;

        ## DETERMINE ENTRY + EXIT IMAGES:
        local output=( $( docker_get_start_and_end_points "$service" "$tags" 2> $VERBOSE ) );
        local tagStart="${output[0]}";
        local tagFinal="${output[1]}";
        [ "$tagStart" == "" ] && _log_fail "Could not find an existing image with one of the tags in \033[1m$tags\033[0m for the service \033[1m$service\033[0m.";

        ## RUN SCRIPT COMMAND WITHIN DOCKER:
        local save_arg="";
        ( $save ) && save_arg="--save \"$tagFinal\"";
        local cmd_arg="";
        ! [ $command == "" ] && cmd_arg="--command \"$command\"";
        # alternative: "--command \"cat $script | dos2unix | bash -s -- $params\"";
        whales_enter_docker --service "$service" --enter "$tagStart" $save_arg --it $it --expose $expose $cmd_arg;

        ## EXIT: Do not return to script!
        exit 0;
    fi
}

##############################################################################
# METHOD: whales_enter_docker
##############################################################################

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
function whales_enter_docker() {
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
    get_docker_service "$service" false;

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
