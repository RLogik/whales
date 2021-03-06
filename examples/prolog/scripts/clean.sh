#!/usr/bin/env bash

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
SERVICE="prolog-service";

source scripts/.lib.sh;

mode="$( get_one_kwarg_space "$SCRIPTARGS" "-+mode" "" )";
tags="$( get_one_kwarg_space "$SCRIPTARGS" "-+tags" "" )";

if [ "$mode" == "docker" ]; then
    source .whales/docker.sh --service "$SERVICE" --clean;
elif [ "$mode" == "artefacts" ]; then
    # whale_call <service> <tag-sequence> <save, it, ports> <type, command>
    whale_call  "$SERVICE" "$tags"        true false false  SCRIPT $ME $SCRIPTARGS;
    run_clean_artefacts;
else
    _log_error   "Invalid cli argument.";
    _cli_message "";
    _cli_message "  Call \033[1m./clean.sh\033[0m with one of the commands";
    _cli_message "    $( _help_cli_key_values      "--mode" "     " "docker" "docker-all" "artefacts" )";
    _cli_message "    $( _help_cli_key_description "--tags" "     " "<string> Sequence of tags from service image tag name, until desired save point post clean." )";
    _cli_message "";
    _cli_message "    $( _help_cli_key_description "--mode docker" "      " "Stops and removes all relevant docker containers + images" )";
    _cli_message "    $( _help_cli_key_description "--mode artefacts" "   " "Use in conjunction with --tags to clean artefacts in docker image." )";
    exit 1;
fi
