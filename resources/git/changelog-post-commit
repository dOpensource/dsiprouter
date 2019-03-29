#!/usr/bin/env bash
#
# Summary:  Create a changelog on commit
# Author:   DevOpSec <https://github.com/devopsec>
# Notes:    Original idea from Martin Seeler <https://github.com/MartinSeeler>
# Usage:    Copy to your repo in <repo>/.git/hooks/post-commit
#           Alternatively the create_changelog function can be used independently (-c option)
#

# project root
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
# destination changelog file
CHANGELOG_FILE="CHANGELOG.md"
# indicator that we commit the changelog
INDICATOR_FILE="${PROJECT_ROOT}/.changelog_commited"

create_changelog() {
    # give it a header
    printf '%s\n\n\n\n' "## $(echo -n ${CHANGELOG_FILE} | rev | cut -d '.' -f 2- | rev)" > ${CHANGELOG_FILE}

    # add changes from the commits
    git --no-pager log --branches --no-merges --format='### %s%n%N%n%NBRANCH_TAG_INFO%n%N> Date: %aD  %n%N> Author: %aN (%aE)  %n%N> Committer: %cN (%cE)  %n%N%n%NBODY_INFO%n%N%n%N---%n%N%n%N' >> ${CHANGELOG_FILE}

    # grab all commits except merges
    # to only get currently staged commits add:
    # --not --remotes
    COMMIT_HASHES=$(git --no-pager log --branches --no-merges --format='%H')

    # add the branch and tag info changelog
    for HASH in $COMMIT_HASHES; do
        # safe formatting needed for sed / bash expansion throughout
        BRANCHES=$(git branch --contains "${HASH}" | perl -pe 's/.+?(?=[\w\d])(.*)/\1/gm' | tr '\n' ',' | rev | cut -d ',' -f 2- | rev)
        TAGS=$(git show-ref --tags -d | grep "^${HASH}" | sed -e 's,.* refs/tags/,,' -e 's/\^{}//' | tr -d '\n')
        # label the pertinent data
        REFERENCE_INFO="> Branches Affected: ${BRANCHES}  \n> Tags Affected: ${TAGS}  "
        BODY_INFO=$(git log --format=%b -n 1 ${HASH})
        # replace any delims (/) with placeholder (~~)
        REFERENCE_INFO=$(sed 's|/|~~|g' <<<"$REFERENCE_INFO")
        BODY_INFO=$(sed 's|/|~~|g' <<<"$BODY_INFO")
        # start formatting as markdown
        BODY_INFO=$(
            # delete empty lines
            sed '/^$/d' <<<"$BODY_INFO" |
            # indented lines -> bullets
            sed -r 's/^[^0-9a-zA-Z]+/- /' |
            # non indented lines -> paragraph
            perl -0777 -pe 's/(- .+?|> .+?)(?:\n)([0-9a-zA-Z].+?)(?=- )/$1\n\n$2\n/gms' |
            # newlines -> literal newlines
            while read -r LINE; do printf '%s\\n' "${LINE}"; done
        )
        # add to the changelog
        sed -i "0,/BRANCH_TAG_INFO/{s/BRANCH_TAG_INFO/$REFERENCE_INFO/}" ${CHANGELOG_FILE}
        sed -i "0,/BODY_INFO/{s/BODY_INFO/$BODY_INFO/}" ${CHANGELOG_FILE}
        # replace placeholders (~~) with original chars (/)
        sed -i 's|~~|/|g' ${CHANGELOG_FILE}
    done
}

# start at project root
cd ${PROJECT_ROOT}

# allow execution outside of git hook
if (( $# > 0 )) && [[ "$1" == "-c" ]]; then
    create_changelog
    exit 0
fi

# prevent recursion
# since a 'commit --amend' will trigger the post-commit script again
# we have to check if the changelog file has been commited yet
# if changelog commited this is recursive call, do nothing
if [[ -e ${INDICATOR_FILE} ]]; then
    rm -f ${INDICATOR_FILE}
else
    touch ${INDICATOR_FILE}
    create_changelog
    git add ${CHANGELOG_FILE}
    git commit --amend -C HEAD --no-verify
fi

exit 0