#!/bin/bash

##############################################################################
#    DESCRIPTION: Script for running programme.
#
#    Usage:
#    ~~~~~~
#    . .docker.sh
#        --base <tag>
#        [--start [--mount|--debug]]
#        [--stop]
#        [--status]
#        [--clean] [--clean-all]
#        [--enter <image:tag>] [--command="..."] [--save <image/image:tag>] [--it=<bool>] [--expose=<bool>]
#
#    Cli options:
#    ~~~~~~~~~~~~
#    --base
#       <tag>              (required) Name of base image's tag.
#    --start               Builds docker service main.
#        --mount           (optional) Use with --start to build the service main-mounted, which mounts the local volume.
#        --debug           (optional) Use with --start to build the service main-debug, which mounts the local volume + bashscripts.
#    --stop                Stops all docker containers.
#    --status              Gets status of all containers and images.
#    --clean               Removes container + images bar base.
#    --clean-all           !!! warning !!! removes ALL docker containers + images, incl. project unrelated ones.
#    --enter               Enters docker container for explorative testing, starting with the base image.
#        <image:tag>       (optional) Enters specifically named docker image:tag.
#                              For image:tag argument run docker ps -a or ./docker.sh --status
#                              Defaults to explore:latest, if left empty and --enter is used
#        --command         (optional) Use in conjunction with --enter, to start container with a command.
#                              Defaults to "bash", if left empty.
#        --save            (optional) If used, will save the container to an image upon completion.
#                              If argument left empty, will overwrite original.
#        --it=true         Docker will run in interactive mode.
#        --it=false        Docker will run in non-interactive mode, discretely and logs will be followed.
#          (default)
#        --expose=true     (Default if --it=true.) Ports will be exposed.
#        --expose=false    (Default if --it=false.) Ports will not be exposed.
##############################################################################

SCRIPTARGS="$@";

. .lib.sh;

set_base_tag "$( get_one_kwarg_space "$SCRIPTARGS" "-+base" )";

if ( has_arg "$SCRIPTARGS" "-+(start|up)" ); then
    service="$DOCKER_SERVICE_MAIN";
    if ! [ "$DOCKER_TAG_BASE" == "" ]; then
        # service="$service:$DOCKER_TAG_BASE";
        service="$DOCKER_TAG_BASE"; ## <-- tag_name coincides with container name in docker-compose.
    fi
    _log_info "START DOCKER SERVICE \033[92;1m$service\033[0m.";
    docker-compose up --build $service;
elif ( has_arg "$SCRIPTARGS" "-+(stop|down)" ); then
    docker-compose stop;
    docker-compose down;
elif ( has_arg "$SCRIPTARGS" "-+clean-all" ); then
    _log_warn "ALL docker containers and images will be stopped and removed. That includes containers not related to this project."
    _cli_ask "Do you wish to proceed? (y/n) "
    read answer;
    if ( check_answer "$answer" ); then
        _log_info "STOP AND REMOVE ALL CONTAINERS";
        docker_remove_all_containers
        _log_info "REMOVE ALL CONTAINERS";
        docker_remove_all_images
    else
        _log_info "SKIPPING";
    fi
elif ( has_arg "$SCRIPTARGS" "-+clean" ); then
    docker_remove_ids part=container key="{{.Names}}"               pattern="^${DOCKER_CONTAINER_TEMP}($|_[0-9]+$)";
    docker_remove_ids part=image     key="{{.Repository}}:{{.Tag}}" pattern="^$DOCKER_IMAGE:$DOCKER_TAG_EXPLORE$";
    docker image prune -a --force; ## prunes any image non used by a container and any dangling images.
elif ( has_arg "$SCRIPTARGS" "-+(status|state)" ); then
    _log_info "Container states:"
    docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Size}}\t{{.Status}}\t{{.CreatedAt}} ago';
    # # docker-compose ps -a;
    _log_info "Images:"
    docker images -a --format 'table {{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}';
elif ( has_arg "$SCRIPTARGS" "-+(enter|explore)" ); then
    _log_info "ENTER DOCKER ENVIRONMENT.";
    ## Check if base image is present (contains mounted volume):
    image_base="$( docker_get_image_id_base )";
    if [ "$image_base" == "" ]; then exit 1; fi

    entry="$( get_one_kwarg_space "$SCRIPTARGS" "-+enter" )";
    entry_orig="$entry";
    if [ "$entry" == "" ]; then
        entry_orig="$DOCKER_IMAGE:$DOCKER_TAG_EXPLORE";
        entry="$( docker_get_image_name_latest_stage "$DOCKER_TAG_EXPLORE" )";
    fi

    id="$( docker_get_id_from_image_tag "$entry" )";
    if [ "$id" == "" ]; then exit 1; fi
    _log_info "CONTINUE WITH IMAGE \033[92;1m$entry\033[0m (\033[93;1m$id\033[0m).";

    ## Set command, if empty:
    it="$( get_kwarg "$SCRIPTARGS" "-+it" "false")";
    command="$( get_kwarg "$SCRIPTARGS" "-+command" "")";
    if [ "$command" == "" ]; then
        command="$DOCKER_CMD_EXPLORE";
        it=true;
    fi
    if ! [ "$it" == "false" ]; then it=true; fi

    ## Set ports command:
    expose="$( get_kwarg "$SCRIPTARGS" "-+expose" "$it")"; ## defaults to true/false dep. on --it argument
    [ "$expose" == "true" ] && ports_option="-p $DOCKER_PORTS" || ports_option="";

    ## Enter docker container and run command:
    container_tmp="$( docker_create_unused_container_name )";
    _log_info "START TEMPORARY CONTAINER \033[92;1m$container_tmp\033[0m.";
    if [ "$it" == "true" ]; then
        _log_info "EXECUTE COMMAND <\033[93;1m$command\033[0m> INTERACTIVELY.";
        docker run --name=$container_tmp $ports_option -it $id bash -c "$command";
    else
        _log_info "EXECUTE COMMAND <\033[93;1m$command\033[0m> NON-INTERACTIVELY.";
        docker run --name=$container_tmp $ports_option -d $id bash -c "$command";
        docker logs --follow $container_tmp;
    fi

    ## Save state upon exit:
    _log_info "WAIT FOR CONTAINER \033[92;1m$container_tmp\033[0m TO STOP.";
    wait_for_container_to_stop "$container_tmp";
    if ( has_arg "$SCRIPTARGS" "-+save" ); then
        image="$( get_one_kwarg_space "$SCRIPTARGS" "-+save" "" )";
        if ( echo "$image" | grep -E -q "^$|^$entry_orig$" ); then
            image="$entry_orig";
            _log_info "SAVE STATE TO \033[92;1m$image\033[0m (OVERWRITING).";
        else
            _log_info "SAVE STATE TO \033[92;1m$image\033[0m.";
        fi
        docker commit $container_tmp $image >> $VERBOSE;
    fi
    docker_remove_container $container_tmp 2> $VERBOSE >> $VERBOSE;
    _log_info "TEMPORARY CONTAINER \033[92;1m$container_tmp\033[0m TERMINATED.";
fi
