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
SERVICE="prolog-service";

source scripts/.lib.sh;

mode="$( get_one_kwarg_space "$SCRIPTARGS" "-+mode" "")";

if [ "$mode" == "setup" ]; then
    # whale_call <service>  <tag-sequence> <save, it, ports> <type, command>
    whale_call   "$SERVICE" "."            true false true  SCRIPT $ME $SCRIPTARGS;
    run_main;
elif [ "$mode" == "unit" ]; then
    # whale_call <service>  <tag-sequence> <save, it, ports> <type, command>
    whale_call   "$SERVICE" ".,unit"       false false true  SCRIPT $ME $SCRIPTARGS;
    run_test_unit;
elif [ "$mode" == "explore" ]; then
    # whale_call <service>  <tag-sequence> <save, it, ports> <type, command>
    whale_call   "$SERVICE" ".,(explore)"  true true true    SCRIPT $ME $SCRIPTARGS;
    run_explore_console;
else
    _log_error   "Invalid cli argument.";
    _cli_message "";
    _cli_message "  Call \033[1m./build.sh\033[0m with one of the commands";
    _cli_message "    $( _help_cli_key_values      "--mode" "         " "setup" "unit" "explore" )";
    _cli_message "    $( _help_cli_key_description "--mode setup" "   " "compiles programme with test configuration" )";
    _cli_message "    $( _help_cli_key_description "--mode unit" "    " "runs unit test" )";
    _cli_message "    $( _help_cli_key_description "--mode explore" " " "opens the console (potentially in docker)" )";
    _cli_message "";
    exit 1;
fi
