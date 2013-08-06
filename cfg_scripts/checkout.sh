#!/bin/bash

set -e

ACCOUNT=git@github.com:imazen-discovery

REPO=$1
BRANCH=$2

if [ -z "$REPO" ]; then
    echo "No repository given."
    exit 1
fi

cd `cat BUILD_DIR`

if [ -d $REPO ]; then
    echo "$REPO present.  Skipping checkout."
    exit 0
fi

git clone $ACCOUNT/$REPO.git
cd $REPO
[ -n "$BRANCH" ] && git checkout "$BRANCH"

# Ensure this exits with a correct status
exit 0
