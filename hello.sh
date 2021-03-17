#!/bin/bash

##############################################################################
#    DESCRIPTION: A hello-world script for development purposes only.
#
#    Usage:
#    ~~~~~~
#    ./hello.sh [--base <tag>] "...message to be printed..."
##############################################################################

SCRIPTARGS="$@";
splitargs=( "$@" );

source whales_setup/.lib.whales.sh;
source whales_setup/.lib.sh;

base_tag="$( get_one_kwarg_space "$SCRIPTARGS" "-+base" "hello" )";
FILE_MESSAGE="HELLO_WORLD";

if ( has_arg "$SCRIPTARGS" "-+base" ); then SCRIPTARGS="${splitargs[@]:2}"; fi
if [ "$base_tag" == "hello" ] && ! [ -f "$FILE_MESSAGE" ]; then
    echo "cwd1 = $PWD";
    echo "(empty)" >| $FILE_MESSAGE;
fi

## check if inside docker, if not then call script within docker:
# call_within_docker <base_tag> <tag>                 <save> <it>  <expose_ports> <script>   <params>
call_within_docker  "$base_tag" "$DOCKER_TAG_EXPLORE" true   false false          "hello.sh" "$SCRIPTARGS";

if ! [ -f "$FILE_MESSAGE" ]; then
    echo "cwd2 = $PWD";
    echo "(empty)" >| $FILE_MESSAGE;
fi
old_message="$(cat $FILE_MESSAGE)";
new_message="$SCRIPTARGS";
echo "$new_message" >| $FILE_MESSAGE;

function print_message() {
    msg="$2";
    if ! ( echo "$msg" | grep -E -q "[^[:space:]]" ); then msg="(empty)"; fi
    echo -e "" >> $OUT;
    echo -e "                                       " >> $OUT;
    echo -e " /¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯\       v ˇ        " >> $OUT;
    echo -e " | \033[2;3m$1\033[0m                 "  >> $OUT;
    echo -e " | \033[96m$msg\033[0m                 " >> $OUT;
    echo -e " \______  __________/                  " >> $OUT;
    echo -e "        \ |                      .     " >> $OUT;
    echo -e "         \|                    ==      " >> $OUT;
    echo -e "          \                 ===        " >> $OUT;
    echo -e "     /''''**'''''''''''\___/ ===       " >> $OUT;
    echo -e "~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ / ====- ~~~~" >> $OUT;
    echo -e "####\|||||||| ^   U    __/######==#####" >> $OUT;
    echo -e "##### ¯¯¯¯¯¯¯¯\_______/###########.####" >> $OUT;
    echo -e "#######################################" >> $OUT;
    echo -e "#######################################" >> $OUT;
    echo -e "" >> $OUT;
}

print_message "Old message:" "$old_message";
print_message "New message:" "$new_message";
