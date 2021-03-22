#!/bin/bash

##############################################################################
#    DESCRIPTION: .ENV EXTRACTION
##############################################################################

function env_value() {
    [ -f "$1" ] && source "$1" && echo "${!2}";
}

function env_required() {
    ! [ -f "$1" ] && echo -e "[\033[91mERROR\033[0m] Could not find environment file \033[1m$1\033[0m!" >> /dev/stderr && return 1;
    source "$1";
    local value="${!2}";
    [ "$value" == "" ] && echo -e "[\033[91mERROR\033[0m] Argument \033[93;1m$2\033[0m not found in \033[1m$1\033[0m!" >> /dev/stderr && return 1;
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

export OUT="$(           env_required ".env" WHALES_CONSOLE_OUT )";
export ERR="$(           env_required ".env" WHALES_CONSOLE_ERR )";
export VERBOSE="$(       env_required ".env" WHALES_CONSOLE_VERBOSE )";
export DEBUG_FILE="$(    env_required ".env" WHALES_CONSOLE_DEBUG_FILE )";
export PATH_LOGS="$(     env_required ".env" WHALES_CONSOLE_PATH_LOGS )";
export LOGGINGPREFIX="";
