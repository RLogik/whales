################################################################
# !!! The following is an exmaple. Replace this by desired docker image instructions. !!!
FROM ubuntu
#
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

################################################################
# !!! Your build instructions here !!!
#
# # E.g. To avoid writing lots of awkward commands here, one can pack themm in a bash script
# # and (depending on the docker image) run the bash script within the container.
# ARG WHALES_ENTRY_SCRIPT
# RUN [ "/bin/bash", "-c", "[ -f \"${WHALES_ENTRY_SCRIPT}\" ] && source \"${WHALES_ENTRY_SCRIPT}\" || exit 1" ]
#
# # Or, to grant execution permissions:
# RUN [ "/bin/bash", "-c", "ls -a {,$WHALES_SETUP_PATH/}{,.}*.sh 2> /dev/null | xargs -i bash -c \"chmod +x {}\"" ]
#
################################################################
