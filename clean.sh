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

SCRIPTARGS="$@";
FLAGS=( $@ );
ME="clean.sh";

source whales_setup/.lib.whales.sh;
source whales_setup/.lib.sh;

mode="$(    get_one_kwarg_space "$SCRIPTARGS" "-+mode"    "" )";
SERVICE="$( get_one_kwarg_space "$SCRIPTARGS" "-+service" "" )";
TAG="$(     get_one_kwarg_space "$SCRIPTARGS" "-+tag"     "" )";

if [ "$mode" == "docker" ]; then
    run_docker_clean;
elif [ "$mode" == "docker-all" ]; then
    run_docker_clean_all;
elif [ "$mode" == "artefacts" ]; then
    select_service "$SERVICE";
    # call_within_docker <service> <tag>  <save> <it>  <expose_ports> <script> <params>
    call_within_docker  "$SERVICE" "$TAG" true   false false          "$ME"    "$SCRIPTARGS";
    run_clean_artefacts;
else
    _log_error   "Invalid cli argument.";
    _cli_message "";
    _cli_message "  Call \033[1m./clean.sh\033[0m with one of the commands";
    _cli_message "    $( _help_cli_key_values      "--mode" "     " "docker" "docker-all" "artefacts" )";
    _cli_message "    $( _help_cli_key_description "--service" "  " "<string> Name of service in whales_setup/docker-compose.yml" )";
    _cli_message "    $( _help_cli_key_description "--tag" "      " "<string> Tag name for the purposes of saving state post clean." )";
    _cli_message "";
    _cli_message "    $( _help_cli_key_description "--mode docker" "      " "Stops and removes all relevant docker containers + images" )";
    _cli_message "    $( _help_cli_key_description "--mode docker-all" "  " "Stops and removes all docker containers + images" )";
    _cli_message "    $( _help_cli_key_description "--mode artefacts" "   " "Use in conjunction with --service, --tag to clean artefacts in docker image." )";
    exit 1;
fi
