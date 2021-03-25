#!/bin/bash

##############################################################################
#    DESCRIPTION: Library of methods for Whales
#    Include using source whales_setup/.lib.sh
##############################################################################

source whales_setup/.lib.globals.sh;
source whales_setup/.lib.utils.sh;
source whales_setup/.lib.docker.sh;

##############################################################################
# MAIN PROCESSES FOR WHALES
##############################################################################

function run_docker_build() {
    local project="$WHALES_PROJECT_NAME";
    local service="$1";

    _log_info "START DOCKER SERVICE \033[92;1m$service\033[0m.";
    env_create_local;
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
    local project="$WHALES_PROJECT_NAME";
    local service="$1";

    _cli_message "";
    _cli_message "\033[94;1mCONTAINERS\033[0m:";
    docker_remove_some_containers "$project" "$service";
    _cli_message "\033[94;1mIMAGES\033[0m:";
    docker_remove_some_images "$project" "$service";
    _cli_message "";
}

function run_docker_clean_all() {
    _log_warn "ALL docker containers and images will be stopped and removed. That includes containers not related to this project.";
    _cli_ask "Do you wish to proceed? (y/n) ";
    read answer;
    if ( check_answer "$answer" ); then
        _log_info "STOP AND REMOVE ALL CONTAINERS";
        docker_remove_all_containers;
        _log_info "REMOVE ALL CONTAINERS";
        docker_remove_all_images;
    else
        _log_info "SKIPPING";
    fi
}

function get_docker_state() {
    local project="$WHALES_PROJECT_NAME";
    local service="$1";

    _cli_message "";
    _cli_message "\033[94;1mCONTAINERS\033[0m:";
    docker_show_some_containers false "$project" "$service";
    _cli_message "";
    _cli_message "\033[94;1mIMAGES\033[0m:";
    docker_show_some_images true "$project" "$service";
    _cli_message "";

}

function run_docker_enter() {
    local service="$1";
    local tags="$2";

    [ "$tags" == "" ] && tags=".,($WHALES_DOCKER_TAG_EXPLORE)";
    call_within_docker "$service" "$tags" false true true;
}
