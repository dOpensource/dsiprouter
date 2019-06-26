#!/usr/bin/env bash
#
# Summary:  Create requirements.txt on commit
# Author:   DevOpSec <https://github.com/devopsec>
# Usage:    Copy to your repo in <repo>/.git/hooks/pre-commit
#           Alternatively the create_requirements function can be used independently by running script
# Notes:    Requires pipreqs -> pip install pipreqs
#           to add dirs to recursively search, change INCLUDE_DIRS (its an array)
#

# project root
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
# where are the python projects for this repo?
INCLUDE_DIRS=("${PROJECT_ROOT}/gui")
# destination file
REQUIREMENTS_FILE="requirements.txt"
# pipreqs only catches stdlib libraries
INCLUDE_LIBS=('mysqlclient' 'docker')

create_requirements() {
    for PYTHON_PROJECT in ${INCLUDE_DIRS[@]}; do
        OUT_FILE="${PYTHON_PROJECT}/${REQUIREMENTS_FILE}"

        INCLUDE_LIBS=( ${INCLUDE_LIBS[@]} $(pipreqs --print ${PYTHON_PROJECT} 2>/dev/null | sed -r '/^\s*$/d' | sort -u | cut -d '=' -f 1) )
        printf '%s\n' "${INCLUDE_LIBS[@]}" | sort -u > ${OUT_FILE}

        git add ${OUT_FILE}
    done
}

create_requirements
exit 0