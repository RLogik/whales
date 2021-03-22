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

        ## EXIT: Do not return to script!
        exit 0;
    fi
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

function run_docker_prune() {
    # Prune images not used by containers and any dangling images.
    # DEV-NOTE: do not use -a flag, as this will remove images from other projects!
    docker image prune --force;
}

function run_docker_clean() {
    docker_remove_some_containers key="{{.Names}}"               pattern="$( get_container_pattern "$WHALES_DOCKER_SERVICE" )";
    docker_remove_some_images     key="{{.Repository}}:{{.Tag}}" pattern="^$WHALES_DOCKER_IMAGE:.+$";
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
