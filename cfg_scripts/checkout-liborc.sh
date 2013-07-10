#!/bin/bash

set -e

cd `cat BUILD_DIR`

if [ -d orc-4-hax ]; then
    echo "orc-4-hax present.  Skipping checkout."
    exit 0
fi

git clone git@github.com:suetanvil/orc-4-hax.git
cd orc-4-hax
git checkout tweaks-0.4.17



