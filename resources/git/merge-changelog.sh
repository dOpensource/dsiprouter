#
# Summary:  Merge driver for CHANGELOG conflicts
# Author:   DevOpSec <https://github.com/devopsec>
# Usage:    Copy gitconfig to <repo>/.git/config and gitattributes to <repo>/.gitattributes
#
# $1 == %O - temporary file name for the merge base (origin)
# $2 == %A - temporary file name for our version (ours)
# $3 == %B - temporary file name for the other branches version (theirs)
# $4 == %L - conflict marker length
# $5 == %P - the original path quoted for the shell
#

# TODO: make more elegant solution; such as diffing & merging then rewriting changelog
# possible example (if no other conflicts update changelog):
#
#PROJECT_ROOT="$(git rev-parse --show-toplevel)"
#
#CONFLICTS=$(git diff --cached --name-only -S '<<<<<<')
#if ! echo "$CONFLICTS" | grep -q -v 'CHANGELOG.md'; then
#    ${PROJECT_ROOT}/.git/hooks/post-commit
#fi

# For now just keep our version of CHANGELOG.md and update on next commit
exit 0
