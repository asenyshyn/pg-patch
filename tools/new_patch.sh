#!/bin/bash

BASE_PATH="$( cd "$( dirname "$0" )" && pwd )"

# create new patch
cat tools/patch_template.sql | sed 's/<%.*%>/'$1'/' | tee patches/$1.sql
