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

if [ "$mode" == "unit" ]; then
    run_tests_unit;
elif [ "$mode" == "e2e" ]; then
    run_tests_e2e;
else
    _log_error   "Invalid cli argument.";
    _cli_message "";
    _cli_message "  Call \033[1m./build.sh\033[0m with one of the commands";
    _cli_message "    $( _help_cli_key_values      "--mode" "       " "unit" "e2e" )";
    _cli_message "    $( _help_cli_key_description "--mode unit" "  " "Runs unit tests." )";
    _cli_message "    $( _help_cli_key_description "--mode e2e" "   " "Runs e2e tests." )";
    _cli_message "";
    exit 1;
fi
