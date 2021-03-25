################################################################
# DOCKER IMAGE: STRAWBERRY PROLOG
FROM swipl:stable
#
################################################################

################################################################################
# INSTRUCTIONS REQUIRED FOR WHALES PROJECT
# !!! The following lines are necessary for the Whales project !!!
# DEV-NOTE: Add `&& sleep 5` to lines, in order to see the console output.
################################################################################

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

# Install dos2unix, to make scripts accessible under all OSs:
RUN DEBIAN_FRONTEND=noninteractive && apt-get -y update           2> /dev/null >> /dev/null
RUN DEBIAN_FRONTEND=noninteractive && apt-get install -y dos2unix 2> /dev/null
RUN DEBIAN_FRONTEND=noninteractive && apt-get clean               2> /dev/null >> /dev/null

# make all bash files in project root + whales_setup readable in unix and grant them execution permissions:
RUN [ "/bin/bash", "-c", "ls -a {,$WHALES_SETUP_PATH/}{,.}*.sh 2> /dev/null | xargs -i bash -c \"dos2unix {} && chmod +x {}\"" ]

# NOTE: To avoid writing lots of awkward commands here, one can pack themm in a bash script
# and (depending on the docker image) run the bash script within the container.
ARG WHALES_ENTRY_SCRIPT
RUN [ "/bin/bash", "-c", "[ -f \"${WHALES_ENTRY_SCRIPT}\" ] && cat \"${WHALES_ENTRY_SCRIPT}\" | dos2unix | bash || exit 1" ]
# (Alternative: Use as ENTRYPOINT instead of RUN. )
