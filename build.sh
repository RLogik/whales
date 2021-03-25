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

mode="$( get_one_kwarg_space "$SCRIPTARGS" "-+mode" "" )";

if [ "$mode" == "setup" ]; then
    # whale_call <service>  <tag-sequence>  <save> <it>  <expose> <script> <params>
    whale_call   "$SERVICE" ".,setup"       true   false true     "$ME"    $SCRIPTARGS;
    run_setup;
elif [ "$mode" == "run" ]; then
    # whale_call <service>  <tag-sequence>  <save> <it>  <expose> <script> <params>
    whale_call   "$SERVICE" "setup,run"     false  false true     "$ME"    $SCRIPTARGS;
    run_test;
elif [ "$mode" == "explore" ]; then
    # whale_call <service>  <tag-sequence>    <save> <it>  <expose> <script> <params>
    whale_call   "$SERVICE" "setup,(explore)" false  true  true     "$ME"    $SCRIPTARGS;
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
