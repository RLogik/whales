#!/bin/bash

##############################################################################
#    DESCRIPTION: Script for entry point of base docker container.
##############################################################################

echo "ENTRY SCRIPT STARTED.";

## now in docker, so set depth:
echo "1" >| whales_setup/DOCKER_DEPTH;

## add prefix to logging levels:
echo "export LOGGINGPREFIX=\">\";" >> whales_setup/.lib.logging.sh;

## make all bash files in project root + whales_setup readable in unix and grant them execution permissions:
ls -a {whales_setup/{,.}}*.sh | xargs -i bash -c "dos2unix {}";
ls -a {whales_setup/{,.}}*.sh | xargs -i bash -c "chmod +x {}";
ls -a *.sh | xargs -i bash -c "dos2unix {}"  2> /dev/null;
ls -a *.sh | xargs -i bash -c "chmod +x {}"  2> /dev/null;
ls -a .*.sh | xargs -i bash -c "dos2unix {}" 2> /dev/null;
ls -a .*.sh | xargs -i bash -c "chmod +x {}" 2> /dev/null;

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
echo "cd $WD"                  >> "$HOME/.bash_history";
echo "./build.sh --mode setup" >> "$HOME/.bash_history";
echo "./test.sh  --mode setup" >> "$HOME/.bash_history";

echo "ENTRY SCRIPT FINISHED.";
