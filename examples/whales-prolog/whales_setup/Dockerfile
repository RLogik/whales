################################################################
# DOCKER IMAGE: STRAWBERRY PROLOG
FROM swipl:stable
#
################################################################

################################################################################
# START OF INSTRUCTIONS REQUIRED FOR WHALES PROJECT
# !!! The following lines are necessary for the Whales project !!!
# DEV-NOTE: Add `&& sleep 5` to lines, in order to see the console output.

## Set whale-labels (used for searching):
ARG WHALES_PROJECT_NAME
ARG WHALES_SELECTED_SERVICE
LABEL org.whales.project="${WHALES_PROJECT_NAME}"
LABEL org.whales.service="${WHALES_SELECTED_SERVICE}"
LABEL org.whales.initial=true

ARG WD
COPY . "$WD"
WORKDIR "$WD"

ARG WHALES_SETUP_PATH
# set the Docker-Depth to 1:
RUN echo "1" >| "${WHALES_SETUP_PATH}/DOCKER_DEPTH"
# add prefix to logging levels:
RUN echo "export LOGGINGPREFIX=\">\";" >> "${WHALES_SETUP_PATH}/.lib.globals.sh"

# END OF INSTRUCTIONS REQUIRED FOR WHALES PROJECT
################################################################################

# To avoid writing lots of awkward commands here, one can pack themm in a bash script
# and (depending on the docker image) run the bash script within the container.
ARG ENTRY_SCRIPT
RUN [ "/bin/bash", "-c", "[ -f \"${ENTRY_SCRIPT}\" ] && source \"${ENTRY_SCRIPT}\" || exit 1" ]
