#!/bin/bash

echo "digraph { size=\"16,12\";" > /C/tmp/file.dot
tools/list-dependencies-from-patches.sh patches/*.sql |
    sed 's/^/"/g' |
    sed 's/ /" -> "/g' |
    sed 's/$/";/g' >> /C/tmp/file.dot
echo "}" >> /C/tmp/file.dot
#dot -Nshape=box  /tmp/file.dot > /C/tmp/file.jpeg
