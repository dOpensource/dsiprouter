#!/usr/bin/env bash
# git wrapper: should be sourced by a login script

# extends git command functionality
__gitwrapper() {
    local ARGS=() COMMIT_FLAG=0 REMOTE_NAME=""

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

    # if default remote used we have to lookup the remote name
    if [[ "${REMOTE_NAME}" == "." ]]; then
        REMOTE_NAME=$(git config --get checkout.defaultremote)
    fi
    # if using default and not set then use origin
    REMOTE_NAME=${REMOTE_NAME:-origin}

    export REMOTE_NAME
    command git "${ARGS[@]}"
    unset REMOTE_NAME
}

# Shadows git cmd
git() {
   __gitwrapper "$@"
}
