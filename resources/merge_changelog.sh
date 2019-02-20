#!/usr/bin/env bash

usage() {
    echo "$0 <from branch> <to branch>"
    echo "Summary:  Merge 'from branch' into 'to branc'h overwriting changelog"
    echo "Args:     from branch - branch with commits to merge"
    echo "Args:     to branch   - branch to add commits to"
    echo "Notes:    This script will also toggle post commit hook so changelog is not updated"
    echo "Notes:    This workflow is generally needed when making pull requests between branches"
    echo "Notes:    If you have multiple post commit hooks change variable 'HOOK' accordingly"
}

if (( $# < 2 )); then
    usage && exit 1
fi

BRANCH_TO="$1"
BRANCH_FROM="$2"

REPO="$(git rev-parse --git-dir)"
HOOK="${REPO}/hooks/post-commit"
cd ${REPO}

togglePostCommit() {
    [[ -x ${HOOK} ]] && chmod -x ${HOOK} || chmod +x ${HOOK}
}

git checkout ${BRANCH_TO}
git merge --no-ff ${BRANCH_FROM}
git checkout --theirs -- CHANGELOG.md
togglePostCommit
git commit --no-verify -m "Merge Branch ${BRANCH_FROM} Into ${BRANCH_TO}"
togglePostCommit
git push origin ${BRANCH_TO}

exit 0