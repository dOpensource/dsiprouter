#!/usr/bin/env bash
#
# Summary:  Create requirements.txt on commit
# Author:   DevOpSec <https://github.com/devopsec>
# Usage:    Copy to your repo in <repo>/.git/hooks/pre-commit
#           Alternatively the create_requirements function can be used independently by running script
# Notes:    Requires pipreqs -> pip install pipreqs
#           to add dirs to recursively search, change INCLUDE_DIRS (its an array)
#

START_DIR=$(pwd)
# project root
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
# where are the python projects for this repo?
INCLUDE_DIRS=("${PROJECT_ROOT}/gui")
# destination file
REQUIREMENTS_FILE="requirements.txt"

create_requirements() {
    for PYTHON_PROJECT in ${INCLUDE_DIRS[@]}; do
        cd ${PYTHON_PROJECT}

        pipreqs --print $(pwd) 2>/dev/null | sed -r '/^\s*$/d' | sort -u | cut -d '=' -f 1 > ${REQUIREMENTS_FILE}

        git add ${REQUIREMENTS_FILE}
    done
}

create_requirements
cd ${START_DIR}
exit 0