#!/bin/bash

echo "digraph { size=\"16,12\";"
tools/sh/list-dependencies-from-patches.sh patches/*.sql |
    sed 's/^/"/g' |
    sed 's/ /" -> "/g' |
    sed 's/$/";/g'
echo "}"
