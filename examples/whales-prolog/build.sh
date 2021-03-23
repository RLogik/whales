#!/usr/bin/env bash

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
SERVICE="prod-service";

source .lib.sh;
source whales_setup/.lib.sh;

mode="$( get_one_kwarg_space "$SCRIPTARGS" "-+mode" "")";

if [ "$mode" == "run" ]; then
    # call_within_docker <service>  <tag-sequence>    <save> <it>  <ports> <script> <params>
    call_within_docker   "$SERVICE" "build"           false  false true    "$ME"    $SCRIPTARGS;
    run_main;
elif [ "$mode" == "unit" ]; then
    # call_within_docker <service>  <tag-sequence>    <save> <it>  <ports> <script> <params>
    call_within_docker   "$SERVICE" "build,unit"      false  false true    "$ME"    $SCRIPTARGS;
    run_test_unit;
elif [ "$mode" == "explore" ]; then
    # call_within_docker <service>  <tag-sequence>    <save> <it>  <ports> <script> <params>
    call_within_docker   "$SERVICE" "build,(explore)" true   true  true    "$ME"    $SCRIPTARGS;
    run_explore_console;
else
    _log_error   "Invalid cli argument.";
    _cli_message "";
    _cli_message "  Call \033[1m./build.sh\033[0m with one of the commands";
    _cli_message "    $( _help_cli_key_values      "--mode" "         " "run" "unit" "explore" )";
    _cli_message "    $( _help_cli_key_description "--mode run" "     " "compiles programme with test configuration" )";
    _cli_message "    $( _help_cli_key_description "--mode unit" "    " "runs unit test" )";
    _cli_message "    $( _help_cli_key_description "--mode explore" " " "opens the console (potentially in docker)" )";
    _cli_message "";
    exit 1;
fi
