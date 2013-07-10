#!/bin/bash

# Create (or ensure the presence of) a directory outside of this tree
# which will subsequently be used to checkout and build other
# projects.

set -e

DEST=$1
if [ -z "$DEST" ]; then
    echo "Missing argument."
    exit 1
fi

if [ ! -f Vagrantfile ]; then
    echo "Must be run in the project root."
    exit 1
fi

if [ ! -d "$DEST" ]; then
    echo "Creating '$DEST'"
    mkdir "$DEST"
else
    echo "'$DEST' already exists."
fi

echo "$DEST" > BUILD_DIR
