#!/bin/bash

##############################################################################
#    DESCRIPTION: Script for running tests.
#
#    Usage:
#    ~~~~~~
#    ./clean.sh [options]
#
#    Cli options:
#    ~~~~~~~~~~~~
#    ...
##############################################################################

local SCRIPTARGS="$@";
local FLAGS=( $@ );

source whales_setup/.lib.whales.sh;
source whales_setup/.lib.sh;

local mode="$( get_one_kwarg_space "$SCRIPTARGS" "-+mode" "")";

if [ "$mode" == "docker" ]; then
    run_clean_docker;
elif [ "$mode" == "docker-all" ]; then
    run_clean_docker_all;
else
    _log_error   "Invalid cli argument.";
    _cli_message "";
    _cli_message "  Call \033[1m./clean.sh\033[0m with one of the commands";
    _cli_message "    $( _help_cli_key_values      "--mode" "           " "docker" "docker-all" )";
    _cli_message "    $( _help_cli_key_description "--mode docker" "    " "stops and removes all relevant docker containers + images" )";
    _cli_message "    $( _help_cli_key_description "--mode docker-all"  " "stops and removes all docker containers + images" )";
    exit 1;
fi
