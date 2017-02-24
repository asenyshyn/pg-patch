#!/bin/bash

readonly BASE_PATH="$( cd "$( dirname "$0" )" && pwd )"

LOAD_TAP=0
DROP_TAP=0
LOAD_TEST=0
DROP_TEST=0
DRY_RUN=0
RUN=0

function sed_bin() {
    if [[ ${OSTYPE//[0-9.]} == "solaris" ]]; then
        gsed "$@"
    else
        sed "$@"
    fi
}

function drop_pgtap(){
    echo "BEGIN;"
    echo "DROP SCHEMA IF EXISTS tap CASCADE;"
}

function load_pgtap(){
    echo "BEGIN;"
    echo "DROP SCHEMA IF EXISTS tap CASCADE;"
    echo "CREATE SCHEMA tap;"
    echo "SET search_path = tap;"
    echo "CREATE EXTENSION pgtap WITH SCHEMA tap;"
    echo "RESET search_path;"
}

function load_tests(){
    echo "BEGIN;"
    echo "DROP SCHEMA IF EXISTS tests CASCADE;"
    echo "CREATE SCHEMA tests;"

    export -f sed_bin
    find $BASE_PATH/tests/tests -name '*.sql' -type f -print0 \
        | xargs -0 -I{} bash -c 'sed_bin "s/^\xEF\xBB\xBF//" {}'
}

function drop_tests(){
    echo "BEGIN;"
    echo "DROP SCHEMA IF EXISTS tests CASCADE;"
}

function run_tests(){
    sed_bin 's/^\xEF\xBB\xBF//' $BASE_PATH/tests/run.sql
}

function dry_run(){
    if [ $DRY_RUN -eq 1 ]; then
        echo "ROLLBACK;"
    else
        echo "COMMIT;"
    fi
}

# process parameters
for var in "$@"
do
    lc_var=`echo $var | tr '[A-Z]' '[a-z]'` # lowercase module name
    if [ $lc_var = "-loadtap" ]; then
        LOAD_TAP=1
    elif [ $lc_var = "-droptap" ] ; then
        DROP_TAP=1
    elif [ $lc_var = "-loadtests" ] ; then
        LOAD_TEST=1
    elif [ $lc_var = "-droptests" ] ; then
        DROP_TEST=1
    elif [ $lc_var = "-0" ] ; then
        DRY_RUN=1
    elif [ $lc_var = "-run" ] ; then
        RUN=1
    fi
done

if [ $DROP_TAP -eq 1 ] ; then
    drop_pgtap
    dry_run
fi

if [ $LOAD_TAP -eq 1 ] ; then
    load_pgtap
    dry_run
fi

if [ $LOAD_TEST -eq 1 ] ; then
    load_tests
    dry_run
fi

if [ $DROP_TEST -eq 1 ] ; then
    drop_tests
    dry_run
fi

if [ $RUN -eq 1 ] ; then
    run_tests
fi
