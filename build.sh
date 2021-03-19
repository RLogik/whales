#!/bin/bash

##############################################################################
#    DESCRIPTION: Script for running tests.
#
#    Usage:
#    ~~~~~~
#    ./build.sh [options]
#
#    Cli options:
#    ~~~~~~~~~~~~
#    ...
##############################################################################

SCRIPTARGS="$@";
FLAGS=( $@ );
ME="build.sh";
SERVICE="prod";

source whales_setup/.lib.whales.sh;
source whales_setup/.lib.sh;

mode="$( get_one_kwarg_space "$SCRIPTARGS" "-+mode" "" )";

if [ "$mode" == "setup" ]; then
    # call_within_docker <service>  <tag>     <save> <it>  <expose_ports> <script> <params>
    call_within_docker   "$SERVICE" "setup"   false  true  true           "$ME"    $SCRIPTARGS;
    run_setup;
elif [ "$mode" == "run" ]; then
    # call_within_docker <service>  <tag>     <save> <it>  <expose_ports> <script> <params>
    call_within_docker   "$SERVICE" "run"     false  false true           "$ME"    $SCRIPTARGS;
    run_test;
elif [ "$mode" == "exlore" ]; then
    # call_within_docker <service>  <tag>     <save> <it>  <expose_ports> <script> <params>
    call_within_docker   "$SERVICE" "explore" false  true  true           "$ME"    $SCRIPTARGS;
    run_explore_console;
else
    _log_error   "Invalid cli argument.";
    _cli_message "";
    _cli_message "  Call \033[1m./build.sh\033[0m with one of the commands";
    _cli_message "    $( _help_cli_key_values      "--mode" "         " "setup" "run" "explore" )";
    _cli_message "    $( _help_cli_key_description "--mode setup" "   " "compiles programme" )";
    _cli_message "    $( _help_cli_key_description "--mode run" "     " "runs the programme" )";
    _cli_message "    $( _help_cli_key_description "--mode explore" " " "opens the console (potentially in docker)" )";
    _cli_message "";
    exit 1;
fi
