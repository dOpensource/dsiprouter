#!/usr/bin/env bash
# git wrapper: should be sourced by a login script

# extends git command functionality
__gitwrapper() {
    local ARGS=() COMMIT_FLAG=0 REMOTE_NAME="origin"

    while (( $# > 0 )); do
        case "$1" in
            commit)
                ARGS+=("$1")
                COMMIT_FLAG=1
                shift
                ;;
            --remote=*)
                if (( ${COMMIT_FLAG} == 1 )); then
                    REMOTE_NAME=$(printf '%s' "$1" | cut -d '=' -f 2-)
                else
                    ARGS+=("$1")
                fi
                shift
                ;;
            *)
                ARGS+=("$1")
                shift
                ;;
        esac
    done

    export REMOTE_NAME
    command git "${ARGS[@]}"
    unset REMOTE_NAME
}

# Shadows git cmd
git() {
   __gitwrapper "$@"
}
