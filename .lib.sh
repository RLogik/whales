#!/bin/bash

##############################################################################
# !!! When creating a Whales project, add to + change methods in this file !!!
#
#    DESCRIPTION: Library of methods specifically for the project.
#    Include using source whales_setup/.lib.sh
#
##############################################################################

source whales_setup/.lib.utils.sh;

##############################################################################
# GLOBAL VARIABLES
##############################################################################

# NOTE: do not use /bin/bash. Results in error under Windows.  Use \/bin\/bash, bash, sh -c bash, or sh.
export CMD_EXPLORE="bash";

##############################################################################
# MAIN METHODS: PROCESSES
##############################################################################

function run_setup() {
    _log_info "Setup process complete!";
    # < your code here > #
}

function run_test_unit() {
    _log_warn "Unit tests not yet implemented!";
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

function run_clean_artefacts() {
    _log_warn "Clean process not yet implemented!";
}
