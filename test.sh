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

. .lib.sh;

mode="$( get_one_kwarg_space "$SCRIPTARGS" "-+mode" "")";

if [ "$mode" == "setup" ]; then
    # call_within_docker <base_tag> <tag>     <save> <it>  <expose_ports> <script>  <params>
    call_within_docker   "test"     "setup"   false  true  true           "test.sh" $SCRIPTARGS;
    run_setup;
elif [ "$mode" == "unit" ]; then
    # call_within_docker <base_tag> <tag>     <save> <it>  <expose_ports> <script>  <params>
    call_within_docker   "test"      "unit"   false  false true           "test.sh" $SCRIPTARGS;
    run_test_unit;
elif [ "$mode" == "exlore" ]; then
    # call_within_docker <base_tag> <tag>     <save> <it>  <expose_ports> <script>  <params>
    call_within_docker   "test"     "explore" false  true  true           "test.sh" $SCRIPTARGS;
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
