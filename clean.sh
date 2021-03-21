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

source .lib.sh;
source whales_setup/.lib.sh;

mode="$(    get_one_kwarg_space "$SCRIPTARGS" "-+mode"    "" )";
SERVICE="$( get_one_kwarg_space "$SCRIPTARGS" "-+service" "" )";
TAGS="$(     get_one_kwarg_space "$SCRIPTARGS" "-+tags"     "" )";

if [ "$mode" == "docker" ]; then
    select_service "$SERVICE" || exit 1;
    run_docker_clean;
elif [ "$mode" == "docker-all" ]; then
    run_docker_clean_all;
elif [ "$mode" == "artefacts" ]; then
    select_service "$SERVICE" || exit 1;
    # call_within_docker <service> <tag-sequence> <save> <it>  <expose> <script> <params>
    call_within_docker  "$SERVICE" "$TAGS"        true   false false    "$ME"    "$SCRIPTARGS";
    run_clean_artefacts;
else
    _log_error   "Invalid cli argument.";
    _cli_message "";
    _cli_message "  Call \033[1m./clean.sh\033[0m with one of the commands";
    _cli_message "    $( _help_cli_key_values      "--mode" "     " "docker" "docker-all" "artefacts" )";
    _cli_message "    $( _help_cli_key_description "--service" "  " "<string> Name of service in whales_setup/docker-compose.yml" )";
    _cli_message "    $( _help_cli_key_description "--tags" "     " "<string> Sequence of tags from service image tag name, until desired save point post clean." )";
    _cli_message "";
    _cli_message "    $( _help_cli_key_description "--mode docker" "      " "Use in conjunction with --service. Stops and removes all relevant docker containers + images" )";
    _cli_message "    $( _help_cli_key_description "--mode docker-all" "  " "Stops and removes all docker containers + images" )";
    _cli_message "    $( _help_cli_key_description "--mode artefacts" "   " "Use in conjunction with --service, --tags to clean artefacts in docker image." )";
    exit 1;
fi
