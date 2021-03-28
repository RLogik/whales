################################################################
# !!! The following is an exmaple. Replace this by desired docker image instructions. !!!
FROM haskell:8.4.4
#
#
################################################################

################################################################################
# START OF INSTRUCTIONS REQUIRED FOR WHALES PROJECT
# !!! The following lines are necessary for the Whales project !!!
# DEV-NOTE: Add `&& sleep 5` to lines, in order to see the console output.

# NOTE: some default values are sent from .whales scripts via --build-arg flag,
# but user can overwrite these with their own env-values + docker-compose.yml
ARG WHALES_SETUP_PATH
ARG WHALES_PROJECT_NAME
ARG WHALES_SELECTED_SERVICE

## Set whale-labels (used for searching):
LABEL org.whales.project="${WHALES_PROJECT_NAME}"
LABEL org.whales.service="${WHALES_SELECTED_SERVICE}"
LABEL org.whales.initial=true

ARG WD
COPY . "$WD"
WORKDIR "$WD"

# set the Docker-Depth to 1:
RUN echo "1" >| "${WHALES_SETUP_PATH}/DOCKER_DEPTH"
# add prefix to logging levels:
RUN echo "export LOGGINGPREFIX=\">\";" >> "${WHALES_SETUP_PATH}/.lib.globals.sh"

# END OF INSTRUCTIONS REQUIRED FOR WHALES PROJECT
################################################################################

# !!! Your build instructions here !!!
