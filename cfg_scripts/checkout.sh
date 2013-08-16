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

if [ ! -d $REPO ]; then
    git clone $ACCOUNT/$REPO.git
fi

cd $REPO

# Checkout the branch if necessary.
if [ -n "$BRANCH" ]; then
    git checkout "$BRANCH"
fi

# And do a pull
git pull

# Ensure this exits with a correct status
exit 0
