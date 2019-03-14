#!/usr/bin/env bash

usage() {
    echo "$0 <from branch> <to branch>"
    echo "Summary:  Merge 'from branch' into 'to branch' overwriting changelog"
    echo "Args:     from branch - branch with commits to merge"
    echo "Args:     to branch   - branch to add commits to"
    echo "Notes:    This script will also toggle git hooks so changelog is not updated"
    echo "Notes:    This workflow is generally needed when making pull / merge requests between branches"
}

if (( $# < 2 )); then
    usage && exit 1
fi

BRANCH_TO="$1"
BRANCH_FROM="$2"

REPO="$(git rev-parse --git-dir)"
HOOKS_DIR="${REPO}/hooks"
cd ${REPO}

git checkout ${BRANCH_TO}
git merge --no-ff ${BRANCH_FROM}
git checkout --theirs -- CHANGELOG.md
# disable hooks
chmod -x ${HOOKS_DIR}/*
git commit --no-verify -m "Merge Branch ${BRANCH_FROM} Into ${BRANCH_TO}"
# enable hooks
chmod +x ${HOOKS_DIR}/*
git push origin ${BRANCH_TO}

exit 0