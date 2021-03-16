#!/bin/bash

##############################################################################
#    DESCRIPTION: Script for entry point of base docker container.
##############################################################################

echo "ENTRY SCRIPT STARTED.";

## now in docker, so set depth:
echo "1" >| DOCKER_DEPTH;

## add prefix to logging levels:
echo "export LOGGINGPREFIX=\">\";" >> .logging.sh;

## make all bash files in project root readable in unix and grant them execution permissions:
ls .*.sh *.sh | xargs -i bash -c "dos2unix {}";
ls .*.sh *.sh | xargs -i bash -c "chmod +x {}";

################################################################
# !!! start of your code !!!
# (install and initialise whatever else is needed)
#
#
#
#
#
#
#
#
# !!! end of your code !!!
################################################################

## add a few entries to bash-history:
echo "cd /usr/apps/whales" >> $HOME/.bash_history;
echo "./test.sh --mode unit"   >> $HOME/.bash_history;

echo "ENTRY SCRIPT FINISHED.";