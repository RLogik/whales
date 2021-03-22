################################################################
# !!! The following is an exmaple. Replace this by desired docker image instructions. !!!
FROM ubuntu
ARG DEBIAN_FRONTEND=noninteractive
#
#
#
################################################################

################################################################################
# INSTRUCTIONS FOR WHALES PROJECT
# !!! The following lines are necessary for the Whales project !!!
################################################################################

ARG WD
COPY . "$WD"
WORKDIR "$WD"

ARG SETUP_PATH
# set the Docker-Depth to 1:
RUN echo "1" >| "$SETUP_PATH/DOCKER_DEPTH"
# add prefix to logging levels:
RUN echo "export LOGGINGPREFIX=\">\";" >> "${SETUP_PATH}/.lib.globals.sh"

# Install dos2unix, to make scripts accessible under all OSs:
RUN apt-get -y update 2> /dev/null >> /dev/null
RUN apt-get install -y dos2unix 2> /dev/null
RUN apt-get clean 2> /dev/null >> /dev/null
# NOTE: To avoid writing lots of awkward commands here, one can pack themm in a bash script
# and (depending on the docker image) run the bash script within the container.
ARG ENTRY_SCRIPT
RUN [ -f "$ENTRY_SCRIPT" ] && cat "$ENTRY_SCRIPT" | dos2unix | bash || exit 1
