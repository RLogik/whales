#!/usr/bin/env bash

##############################################################################
#    DESCRIPTION: Script for cleaning-processes.
#
#    Usage:
#    ~~~~~~
#    ./clean.sh [options]
##############################################################################

SCRIPTARGS="$@";

source .lib.sh;

if ( has_arg "$SCRIPTARGS" "-+all" ); then
    run_remove_all_artefacts "src";
    run_remove_all_artefacts "test";
elif ( has_arg "$SCRIPTARGS" "-+prune" ); then
    run_remove_prune_artefacts "src";
    run_remove_prune_artefacts "test";
else
    _log_error   "Invalid cli argument.";
    _cli_message "";
    _cli_message "  Call \033[1m./clean.sh\033[0m with the commands";
    _cli_message "    $( _help_cli_key_description "--all" "    " "Removes all build artefacts including binary." )";
    _cli_message "    $( _help_cli_key_description "--prune" "  " "Removes all build artefacts expect including binary." )";
    exit 1;
fi
