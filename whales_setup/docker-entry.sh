#!/usr/bin/env bash

##############################################################################
#    DESCRIPTION: Script for entry point of base docker container.
##############################################################################

# !!! entry instructions, e.g. installation code !!!

## add a few entries to bash-history:
echo "cd \"$WD\""              >> "$HOME/.bash_history";
## Further possibilities, to make searching for commands in exploration mode easier:
# echo "./build.sh --mode setup" >> "$HOME/.bash_history";
# echo "./test.sh  --mode setup" >> "$HOME/.bash_history";
