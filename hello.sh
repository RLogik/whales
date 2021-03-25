#!/usr/bin/env bash

##############################################################################
#    DESCRIPTION: A hello-world script for development purposes only.
#
#    Usage:
#    ~~~~~~
#    ./hello.sh "...message to be printed..."
##############################################################################

SCRIPTARGS="$@";
FLAGS=( "$@" );
ME="hello.sh";
SERVICE="hello-service";

source .lib.sh;

FILE_MESSAGE="HELLO_WORLD";

( has_arg "$SCRIPTARGS" "-+base" ) && SCRIPTARGS="${FLAGS[@]:2}";

# whale_call <service>  <tag-sequence> <save, it, ports> <type, command>
whale_call   "$SERVICE" ".,(explore)"  true false false  SCRIPT $ME $SCRIPTARGS;

! [ -f "$FILE_MESSAGE" ] && echo "(empty)" >| $FILE_MESSAGE;
old_message="$(cat $FILE_MESSAGE)";
new_message="$SCRIPTARGS";
echo "$new_message" >| $FILE_MESSAGE;

function print_message() {
    msg="$2";
    if ! ( echo "$msg" | grep -Eq "[^[:space:]]" ); then msg="(empty)"; fi
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
