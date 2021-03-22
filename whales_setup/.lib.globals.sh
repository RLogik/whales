#!/bin/bash

##############################################################################
#    DESCRIPTION: .ENV EXTRACTION
##############################################################################

function env_value() {
    local file="$1";
    local key="$2";
    local pattern="^$key=(.*)$";
    while read line; do
        ! ( echo "$line" | grep -E -q "$pattern" ) && continue;
        echo "$( echo "$line" | sed -E "s/^.*=(.*)$/\1/g" )" && return;
    done <<< "$( cat "$file" )";
}

function env_required() {
    local file="$1";
    local key="$2";
    local value="$( env_value "$file" "$key" )";
    [ "$value" == "" ] && echo -e "[\033[91mERROR\033[0m]Argument \033[93;1m$key\033[0m not found in \033[1m$file\033[0m!" && return 1;
    echo "$value";
}

##############################################################################
# GLOBAL VARIABLES: .lib.whales.sh
##############################################################################

# extract from project .env file:
export WHALES_PATH="$(               env_required ".env" WHALES_SETUP_PATH                 )";
export WHALES_DOCKER_COMPOSE_YML="$( env_required ".env" WHALES_DOCKER_COMPOSE_CONFIG_FILE )";

# extract from whales_seutp .env:
export WHALES_DOCKER_IP="$(               env_required "$WHALES_PATH/.env" IP                      )";
export WHALES_DOCKER_PORT_HOST="$(        env_required "$WHALES_PATH/.env" PORT_HOST               )";
export WHALES_DOCKER_PORT_CONTAINER="$(   env_required "$WHALES_PATH/.env" PORT_CONTAINER          )";
export WHALES_DOCKER_TAG_EXPLORE="$(      env_required "$WHALES_PATH/.env" TAG_EXPLORE             )";
export WHALES_CONTAINER_SCHEME_PREFIX="$( env_required "$WHALES_PATH/.env" CONTAINER_SCHEME_PREFIX )";

export WHALES_DOCKER_SERVICE="";   # NOTE: This get changed dynamically.
export WHALES_DOCKER_IMAGE="";     # ""
export WHALES_DOCKER_CONTAINER=""; # ""
export WHALES_TEMPCONTAINER_SCHEME_PREFIX="temp_$WHALES_CONTAINER_SCHEME_PREFIX";
export WHALES_FILE_DOCKER_DEPTH="$WHALES_PATH/DOCKER_DEPTH";
export WHALES_DOCKER_PORTS="$WHALES_DOCKER_IP:$WHALES_DOCKER_PORT_HOST:$WHALES_DOCKER_PORT_CONTAINER";

# NOTE: do not use /bin/bash. Results in error under Windows.  Use \/bin\/bash, bash, sh -c bash, or sh.
export WHALES_DOCKER_CMD_EXPLORE="bash";

##############################################################################
# GLOBAL VARIABLES: .lib.utils.sh
##############################################################################

# periodic waiting time to check a process;
export WAIT_PERIOD_IN_SECONDS=1;
export PENDING_SYMBOL="#";

##############################################################################
# GLOBAL VARIABLES: logging
##############################################################################

export OUT="$(           env_required "$WHALES_PATH/.env" CONSOLE_OUT )";
export ERR="$(           env_required "$WHALES_PATH/.env" CONSOLE_ERR )";
export VERBOSE="$(       env_required "$WHALES_PATH/.env" CONSOLE_VERBOSE )";
export DEBUG_FILE="$(    env_required "$WHALES_PATH/.env" CONSOLE_DEBUG_FILE )";
export PATH_LOGS="$(     env_required "$WHALES_PATH/.env" CONSOLE_PATH_LOGS )";
export LOGGINGPREFIX="";
