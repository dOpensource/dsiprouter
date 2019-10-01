#!/usr/bin/env bash
#
# Summary:  Create CONTRIBUTORS.md and requirements.txt on commit
# Author:   DevOpSec <https://github.com/devopsec>
# Usage:    Copy to your repo in <repo>/.git/hooks/pre-commit
#           Alternatively the create_contributors function can be used independently by running script
# Notes:    Requires pipreqs -> pip install pipreqs
#           To add directories to recursive search, change INCLUDE_DIRS (its an array)
#

# project root
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
# destination file
CONTRIBUTING_FILE="CONTRIBUTORS.md"
# indicator that we commited the changelog
CHANGELOG_INDICATOR_FILE="${PROJECT_ROOT}/.changelog_commited"
# where are the python projects for this repo?
INCLUDE_DIRS=("${PROJECT_ROOT}/gui")
# destination file
REQUIREMENTS_FILE="requirements.txt"
# pipreqs only catches stdlib libraries
INCLUDE_LIBS=('mysqlclient' 'docker')
# excludes for conflicting libs
EXCLUDE_LIBS=('docker_py')

joinwith() { local START="$1" IFS="$2" END="$3" ARR=(); shift;shift;shift; for VAR in "$@"; do ARR+=("${START}${VAR}${END}"); done; echo "${ARR[*]}"; }

create_contributors() {
    local OUT_FILE="${PROJECT_ROOT}/${CONTRIBUTING_FILE}"

    printf '%s\n\n%s\n\n' \
        "## Thank you to all contributors for your hard work" \
        "### Contributors" > ${OUT_FILE}

    git shortlog -sn HEAD | grep -oP '[\s\d]*\K.*'| awk '{for (i=1; i<=NF; i++) print "- " $0}' | sort -u >> ${OUT_FILE}

    git add ${OUT_FILE}
}

create_requirements() {
    local OUT_FILE=""

    for PYTHON_PROJECT in ${INCLUDE_DIRS[@]}; do
        OUT_FILE="${PYTHON_PROJECT}/${REQUIREMENTS_FILE}"

        if (( ${#EXCLUDE_LIBS[@]} != 0 )); then
            LIBS=( ${INCLUDE_LIBS[@]} $(pipreqs --print ${PYTHON_PROJECT} 2>/dev/null | sed -r '/^\s*$/d' | sort -u | cut -d '=' -f 1 | grep -E -v $(joinwith '^' '|' '$' ${EXCLUDE_LIBS[@]})) )
        else
            LIBS=( ${INCLUDE_LIBS[@]} $(pipreqs --print ${PYTHON_PROJECT} 2>/dev/null | sed -r '/^\s*$/d' | sort -u | cut -d '=' -f 1) )
        fi

        printf '%s\n' "${LIBS[@]}" | sort -u > ${OUT_FILE}

        git add ${OUT_FILE}
    done
}

main() {
    # make sure un-staged and un-tracked code is not checked by this script
    # in the future this will be more important as we add linting
    local STASH_NAME="pre-commit-$(date +%s)"
    git stash save -q -k -u "$STASH_NAME"
    local STASH_ID=$(git stash list | grep "$STASH_NAME" | cut -d ':' -f 1)


    create_contributors
    create_requirements

    git stash apply -q "$STASH_ID"
    git stash drop -q "$STASH_ID"
    exit 0
}

# allow execution outside of git hook
if (( $# > 0 )) && [[ "$1" == "-exec" ]]; then
    main
fi

# prevent recursion
if [[ -e ${CHANGELOG_INDICATOR_FILE} ]]; then
    exit 0
else
    main
fi
