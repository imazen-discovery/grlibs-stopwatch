#!/bin/bash

# Group the input by shrink ratio, size and type

set -e

INPUT=timings.tab
OUTPUT=timings-by-size-and-type.tab

./stats_tools/tabcluster.rb \
    --preamble 3 \
    --fields 5,3,4 \
    --blank \
    $INPUT $OUTPUT

echo "Results in $OUTPUT"



