#!/bin/bash

##############################################################################
#    DESCRIPTION: .ENV EXTRACTION
##############################################################################

function env_value() {
    source "$1";
    bash -c "echo \$$2";
}

function env_required() {
    local file="$1";
    local key="$2";
    local value="$( env_value "$file" "$key" )";
    [ "$value" == "" ] && echo -e "[\033[91mERROR\033[0m]Argument \033[93;1m$key\033[0m not found in \033[1m$file\033[0m!" >> /dev/stderr && return 1;
    echo "$value";
}

##############################################################################
# GLOBAL VARIABLES: logging
##############################################################################

# NOTE: do not use /bin/bash. Results in error under Windows.  Use \/bin\/bash, bash, sh -c bash, or sh.
export CMD_EXPLORE="bash";
# periodic waiting time to check a process;
export WAIT_PERIOD_IN_SECONDS=1;
export PENDING_SYMBOL="#";

export OUT="$(           env_required ".env" CONSOLE_OUT )";
export ERR="$(           env_required ".env" CONSOLE_ERR )";
export VERBOSE="$(       env_required ".env" CONSOLE_VERBOSE )";
export DEBUG_FILE="$(    env_required ".env" CONSOLE_DEBUG_FILE )";
export PATH_LOGS="$(     env_required ".env" CONSOLE_PATH_LOGS )";
export LOGGINGPREFIX="";
