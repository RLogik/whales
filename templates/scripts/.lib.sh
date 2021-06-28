#!/usr/bin/env bash

##############################################################################
#    DESCRIPTION: Library of methods specifically for the project.
#    Include using source .whales/.lib.sh
##############################################################################

source .whales/.lib.sh;

##############################################################################
# GLOBAL VARIABLES
##############################################################################

# env_from ".env" import IP             as DOCKER_IP;
# env_from ".env" import PORT_HOST      as DOCKER_PORT_HOST;
# env_from ".env" import PORT_CONTAINER as DOCKER_PORT_CONTAINER;
# env_from ".env" import PORTS          as DOCKER_PORTS;

##############################################################################
# MAIN METHODS: PROCESSES
##############################################################################

function run_setup() {
    _log_info "Setup process complete!";
    # < your code here > #
}

function run_main() {
    _log_warn "Main process not yet implemented!";
    # < your code here > #
}

function run_explore_console() {
    ## start interaction:
    _log_info "READY TO EXPLORE.";
    $CMD_EXPLORE;
}

function run_test_unit() {
    _log_warn "Unit tests not yet implemented!";
    # < your code here > #
}

function run_clean_artefacts() {
    _log_warn "Clean process not yet implemented!";
}
