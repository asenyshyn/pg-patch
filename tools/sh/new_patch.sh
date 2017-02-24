#!/bin/bash

DB_PATH="$( cd "$( dirname "$0" )" && pwd )"

# create new patch
cat $DB_PATH/../sql/patch_template.sql | sed 's/<%.*%>/'$1'/' | tee $DB_PATH/../../patches/$1.sql
