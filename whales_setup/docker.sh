#!/bin/bash

##############################################################################
#    DESCRIPTION: Script for running programme.
#
#    Usage:
#    ~~~~~~
#    . .docker.sh
#        --service <tag>
#        [--start [--mount|--debug]]
#        [--stop]
#        [--status]
#        [--clean] [--clean-all]
#
#    Cli options:
#    ~~~~~~~~~~~~
#    --service <string>    Name of original service from which image is to be created / extended.
#    --start               Builds docker service main.
#    --stop                Stops all docker containers.
#    --status              Gets status of all containers and images.
#    --clean               Removes container + images bar base.
#    --clean-all           !!! warning !!! removes ALL docker containers + images, incl. project unrelated ones.
##############################################################################

SCRIPTARGS="$@";

source whales_setup/.lib.whales.sh;

service="$( get_one_kwarg_space "$SCRIPTARGS" "-+service" )";

if ( has_arg "$SCRIPTARGS" "-+(start|up)" ); then
    select_service "$service";
    run_docker_start "$SCRIPTARGS";
elif ( has_arg "$SCRIPTARGS" "-+(stop|down)" ); then
    select_service "$service";
    run_docker_stop_down;
elif ( has_arg "$SCRIPTARGS" "-+clean-all" ); then
    run_docker_clean_all;
elif ( has_arg "$SCRIPTARGS" "-+clean" ); then
    set_docker_service "$service" false;
    run_docker_clean;
elif ( has_arg "$SCRIPTARGS" "-+(status|state)" ); then
    get_docker_state;
else
    _log_error   "Invalid cli argument.";
    _cli_message "";
    _cli_message "  Call \033[1m./whales_setup/docker.sh\033[0m with the command";
    _cli_message "    $( _help_cli_key_description "--service" "       " "<string> Name of service in whales_setup/docker-compose.yml." )";
    _cli_message "  and with one of the following commands";
    _cli_message "    $( _help_cli_key_description "--status/state" "  " "Displays status of containers + images." )";
    _cli_message "    $( _help_cli_key_description "--start/up" "      " "Starts container." )";
    _cli_message "    $( _help_cli_key_description "--stop/down" "     " "Stops container." )";
    _cli_message "    $( _help_cli_key_description "--clean" "         " "Cleans all docker images and containers with name 'whales:...'." )";
    _cli_message "    $( _help_cli_key_description "--clean-all" "     " "Cleans+Prunes all docker images and containers after prompt." )";
    _cli_message "";
    exit 1;
fi
