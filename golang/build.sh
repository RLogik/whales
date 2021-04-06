#!/usr/bin/env bash

##############################################################################
#    DESCRIPTION: Script for build-processes.
#
#    Usage:
#    ~~~~~~
#    ./build.sh [options]
##############################################################################

SCRIPTARGS="$@";
FLAGS=( $@ );

source .lib.sh;

validcommand=false;

if ( has_arg "$SCRIPTARGS" "-+requirements" ); then
    run_compile_update_requirements "src";
    validcommand=true;
fi

if ( has_arg "$SCRIPTARGS" "-+compile" ); then
    run_compile_go "src";
    validcommand=true;
fi

if ! ( $validcommand ); then
    _log_error   "Invalid cli argument.";
    _cli_message "";
    _cli_message "  Call \033[1m./build.sh\033[0m with one of the commands";
    _cli_message "    $( _help_cli_key_description "--requirements" "  " "Installs requirements." )";
    _cli_message "    $( _help_cli_key_description "--compile" "       " "Compiles go programme. Use in combination with --requirements to first update requirements, then compile." )";
    _cli_message "";
    exit 1;
fi
