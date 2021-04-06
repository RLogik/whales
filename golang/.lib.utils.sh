#!/bin/bash

##############################################################################
#    DESCRIPTION: Library of common utility functions.
#    Include using source .lib.utils.sh
##############################################################################

# import sames methods from src folder:
source ../src/.lib.utils.sh;

##############################################################################
# AUXILIARY METHODS: GOLANG
##############################################################################

function go_command() {
    go $@;
}

function go_compile() {
    go_command build $@;
}

function go_utest() {
    go_command test $@;
}

function go_load_package() {
    name="$1";
    version="$2";
    [[ "$version" == "" ]] && go_command get "$name" || go_command get "$name@$version";
}
