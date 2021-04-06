#!/bin/bash

##############################################################################
#    DESCRIPTION: Library methods
#    Include using source .lib.sh
##############################################################################

source .lib.utils.sh;

##############################################################################
# GLOBAL VARIABLES:
##############################################################################

# periodic waiting time to check a process;
export WAIT_PERIOD_IN_SECONDS=1;
export PENDING_SYMBOL="#";

# extraction from environments:
export OUT="/dev/stdout";
export ERR="/dev/stderr";
export VERBOSE="/dev/null";
export PATH_LOGS="logs";
export FILENAME_LOGS_DEBUG="debug.log";
export LOGGINGPREFIX="";

export GO_MAIN_FILE="main.go";
export GO_MAIN_BINARY="src/main";
export GO_MAIN_ARTEFACTS=( "go.sum" );
export GO_MANIFESTO_FILE="go.mod";
export GO_TEST_TIMEOUT="60s"; # <- duration in minutes

##############################################################################
# MAIN PROCESSES
##############################################################################

function run_compile_update_requirements() {
    local path="$1";
    local file="$GO_MANIFESTO_FILE";
    local pattern='^require ([^[:space:]]+)([[:space:]]*$|[[:space:]]+\/+.*$|[[:space:]]+([a-z0-9\.-_]+).*$)';
    local line;

    pushd "$path" >> $VERBOSE;
        local has_problems=0;
        local problem_packages=();
        while read line; do
            line="$( echo "$line" | sed -E "s/^[[:space:]]+|[[:space:]]+$//" )";
            [[ "$line" == "" ]] && continue;
            ! ( echo "$line" | grep -Eiq "$pattern" ) && continue;
            local name="$( echo "$line" | sed -E "s/$pattern/\1/gi" )";
            local version="$( echo "$line" | sed -E "s/$pattern/\3/gi" )";
            _log_info "Run \033[92;1mGO GET\033[0m to install \033[93;1m$name\033[0m...";
            ( go_load_package "$name" "$version" 2> $VERBOSE >> $VERBOSE ) && continue;
            has_problems=1;
            problem_packages+=( "$pkg" );
        done <<< "$( cat "$file" )";
    popd >> $VERBOSE;

    if [[ $has_problems == 1 ]]; then
        _log_fail "Something went wrong whilst using \033[92;1mGO GET\033[0m to install the packages: \033[93;1m${problem_packages[*]}\033[0m!";
    fi
}

function run_compile_go() {
    local path="$1";
    local file="$GO_MAIN_FILE";
    _log_info "Run \033[92;1mGO BUILD\033[0m to compile \033[93;1m$file\033[0m...";
    pushd "$path" >> $VERBOSE;
        go_compile "$file";
    popd >> $VERBOSE;
}

function run_tests_unit() {
    _log_info "Run \033[92;1mUNIT TESTS\033[0m...";
    pushd "src" >> $VERBOSE;
        go_utest -v -timeout $GO_TEST_TIMEOUT -count 1 -run "^Test[A-Z].*" "whales" "./...";
    popd >> $VERBOSE;
}

function run_tests_e2e() {
    _log_info "Run \033[92;1mE2E TESTS\033[0m...";
    # local programme="$PWD/src/$GO_MAIN_BINARY";
    _log_warn "Not implemented!";
}

function run_remove_all_artefacts() {
    local path="$1";
    run_remove_prune_artefacts "$path";
    pushd "$path" >> $VERBOSE;
        remove_file "$path/$GO_MAIN_BINARY";
    popd >> $VERBOSE;
}

function run_remove_prune_artefacts() {
    local path="$1";
    pushd "$path" >> $VERBOSE;
        local file;
        for file in "${GO_MAIN_ARTEFACTS[@]}"; do
            [ "$file" == "" ] && continue;
            remove_file "$path/$file";
        done
    popd >> $VERBOSE;
}
