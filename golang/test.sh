#!/usr/bin/env bash

##############################################################################
#    DESCRIPTION: Script for build-processes.
#
#    Usage:
#    ~~~~~~
#    ./build.sh [options]
##############################################################################

SCRIPTARGS="$@";

source .lib.sh;

mode="$( get_one_kwarg_space "$SCRIPTARGS" "-+mode" "" )";

if [ "$mode" == "run" ]; then
    run_programme;
elif [ "$mode" == "unit" ]; then
    run_tests_unit;
elif [ "$mode" == "e2e" ]; then
    run_tests_e2e;
elif [ "$mode" == "explore" ]; then
    run_explore_console;
else
    _log_error   "Invalid cli argument.";
    _cli_message "";
    _cli_message "  Call \033[1m./build.sh\033[0m with one of the commands";
    _cli_message "    $( _help_cli_key_values      "--mode" "          " "run" "unit" "e2e" "explore" )";
    _cli_message "    $( _help_cli_key_description "--mode run" "      " "Runs compiled binary with no arguments." )";
    _cli_message "    $( _help_cli_key_description "--mode unit" "     " "Runs unit tests." )";
    _cli_message "    $( _help_cli_key_description "--mode e2e" "      " "Runs e2e tests." )";
    _cli_message "    $( _help_cli_key_description "--mode explore" "  " "Opens the console (potentially in docker)." )";
    _cli_message "";
    exit 1;
fi
