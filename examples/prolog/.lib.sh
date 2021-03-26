#!/usr/bin/env bash

##############################################################################
# !!! When creating a Whales project, add to + change methods in this file !!!
#
#    DESCRIPTION: Library of methods specifically for the project.
#    Include using source .whales/.lib.sh
#
##############################################################################

source .whales/.lib.sh;

##############################################################################
# GLOBAL VARIABLES
##############################################################################

#

##############################################################################
# AUXILIAR METHODS: Prolog
##############################################################################

function run_prolog() {
    swipl $@;
}

##############################################################################
# MAIN METHODS: PROCESSES
##############################################################################

function run_setup() {
    _log_warn "Setup process not yet implemented!";
    # < your code here > #
}

function run_test_unit() {
    _log_warn "Unit tests not yet implemented!";
    # < your code here > #
}

function run_main() {
    pushd src >> $VERBOSE
        run_prolog -fq main.pl -t halt;
    popd >> $VERBOSE
}

function run_explore_console() {
    ## start interaction:
    _log_info "READY TO EXPLORE.";
    $CMD_EXPLORE;
}

function run_clean_artefacts() {
    _log_warn "Clean process not yet implemented!";
}
