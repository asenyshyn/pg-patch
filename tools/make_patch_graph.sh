#!/bin/bash

echo "digraph { size=\"16,12\";" > /C/tmp/file.dot
tools/list-dependencies-from-patches.sh patches/*.sql |sed 's/ / -> /g' |sed 's/$/;/' >> /C/tmp/file.dot
echo "}" >> /tmp/file.dot
#dot -Nshape=box  /tmp/file.dot > /tmp/file.jpeg
