#!/bin/bash

set -e

./stats_tools/tabcluster.rb \
    --preamble 3 \
    --fields 2,5 \
    --blank \
    resize_timings.tab resize_timings-by-size-and-type.tab


