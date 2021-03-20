#!/bin/bash

##############################################################################
#    DESCRIPTION: Script for running tests.
#
#    Usage:
#    ~~~~~~
#    ./test.sh [options]
#
#    Cli options:
#    ~~~~~~~~~~~~
#    ...
##############################################################################

SCRIPTARGS="$@";
FLAGS=( $@ );
ME="test.sh";
SERVICE="testService";

source .lib.sh;
source whales_setup/.lib.whales.sh;

mode="$( get_one_kwarg_space "$SCRIPTARGS" "-+mode" "")";

if [ "$mode" == "setup" ]; then
    # call_within_docker <service>  <tag-sequence> <save> <it>  <ports> <script> <params>
    call_within_docker   "$SERVICE" "test,setup"   true   false true    "$ME"    $SCRIPTARGS;
    run_setup;
elif [ "$mode" == "unit" ]; then
    # call_within_docker <service>  <tag-sequence> <save> <it>  <ports> <script> <params>
    call_within_docker   "$SERVICE" "setup,unit"   false  false true    "$ME"    $SCRIPTARGS;
    run_test_unit;
elif [ "$mode" == "exlore" ]; then
    # call_within_docker <service>  <tag-sequence>    <save> <it>  <ports> <script> <params>
    call_within_docker   "$SERVICE" "setup,(explore)" true   true  true    "$ME"    $SCRIPTARGS;
    run_explore_console;
else
    _log_error   "Invalid cli argument.";
    _cli_message "";
    _cli_message "  Call \033[1m./test.sh\033[0m with one of the commands";
    _cli_message "    $( _help_cli_key_values      "--mode" "         " "setup" "unit" "explore" )";
    _cli_message "    $( _help_cli_key_description "--mode setup" "   " "compiles programme with test configuration" )";
    _cli_message "    $( _help_cli_key_description "--mode unit" "    " "runs unit test" )";
    _cli_message "    $( _help_cli_key_description "--mode explore" " " "opens the console (potentially in docker)" )";
    _cli_message "";
    exit 1;
fi
