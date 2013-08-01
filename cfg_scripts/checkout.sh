#!/bin/bash

set -e

ACCOUNT=$1
REPO=$2
BRANCH=$3

if [ -z "$REPO" ]; then
    echo "No repository given."
    exit 1
fi

[ -z "$ACCOUNT" ] && ACCOUNT=git@github.com:suetanvil

cd `cat BUILD_DIR`

if [ -d $REPO ]; then
    echo "$REPO present.  Skipping checkout."
    exit 0
fi

git clone $ACCOUNT/$REPO
cd $REPO
[ -n "$BRANCH" ] && git checkout "$BRANCH"



