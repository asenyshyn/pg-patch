#!/bin/bash

readonly DB_PATH="$( cd "$( dirname "$0" )" && pwd )"

DBNAME='';
LOAD_BASE=0;
DRY_RUN=0;

# Functions ========================================

function sed_bin() {
    if [[ ${OSTYPE//[0-9.]} == "solaris" ]]; then
        gsed "$@"
    else
        sed "$@"
    fi
}

function grep_bin() {
    if [[ ${OSTYPE//[0-9.]} == "solaris" ]]; then
        ggrep "$@"
    else
        grep "$@"
    fi
}

function get_module_path {
    local CODE_PATH=''
    if [ -d "$DB_PATH/code/functions/$1/" ]; then
        CODE_PATH="$CODE_PATH $DB_PATH/code/functions/$1/"
    fi
    if [ -d "$DB_PATH/code/views/$1/" ]; then
        CODE_PATH="$CODE_PATH $DB_PATH/code/views/$1/"
    fi
    if [ -d "$DB_PATH/code/rules/$1/" ]; then
        CODE_PATH="$CODE_PATH $DB_PATH/code/rules/$1/"
    fi
    if [ -d "$DB_PATH/code/triggers/$1/" ]; then
        CODE_PATH="$CODE_PATH $DB_PATH/code/triggers/$1/"
    fi

    echo $CODE_PATH
}

function install_modules {

    local MODULE_PATH=''

    MODULE_PATH="$MODULE_PATH $(get_module_path core)"
    MODULE_PATH="$MODULE_PATH $(get_module_path general)"
    MODULE_PATH="$MODULE_PATH $(get_module_path history)"

    export -f sed_bin
    find $MODULE_PATH -name '*.sql' -type f -print0 \
        | xargs -0 -I{} bash -c 'sed_bin "s/^\xEF\xBB\xBF//" {}'

}

function load_permissions() {
    sed_bin 's/^\xEF\xBB\xBF//' $DB_PATH/init/permissions.sql
}

function load_versioning() {
    sed_bin 's/^\xEF\xBB\xBF//' $DB_PATH/tools/sql/install_versioning.sql
}

function load_patches() {
    # before patch. drop recreatable objects
    sed_bin 's/^\xEF\xBB\xBF//' $DB_PATH/tools/sql/before_patch.sql

    echo
    echo "-- apply patches --"
    echo
    # apply incremental changes
    $DB_PATH/tools/sh/list-dependencies-from-patches.sh $DB_PATH/patches/*.sql \
        | tsort \
        | sed_bin '1!G;h;$!d' \
        | xargs -I{} cat $DB_PATH/patches/{}.sql

    # after patch
    sed_bin 's/^\xEF\xBB\xBF//' $DB_PATH/tools/sql/after_patch.sql
}

function lock_for_patch(){

    sed_bin 's/^\xEF\xBB\xBF//' $DB_PATH/tools/sql/header.sql

    # get repository revision global ID and branch name
    #if git
    if hash git 2> /dev/null &&  git rev-parse --git-dir > /dev/null 2>&1 ; then
        REVISION=`git rev-parse HEAD`
        BRANCH=`git rev-parse --abbrev-ref HEAD`
        #if hg
    elif hash hg 2> /dev/null && hg root > /dev/null 2>&1 ; then
        REVISION==`hg id -i`
        BRANCH=`hg id -b`
    elif [ -f repo.info ] ; then
        . repo.info
        REVISION=$B_REVISION
        BRANCH=$B_BRANCH
    else
        REVISION='Unknown. No version control info found'
        BRANCH='Unknown. No version control info found'
    fi

    # start transaction
    echo "BEGIN;"
    echo

    if [ $LOAD_BASE -eq 1 ]; then
        load_versioning
    fi

    # Thanks to this we know only one patch will be applied at a time
    echo "LOCK TABLE _v.patches IN EXCLUSIVE MODE;"
    echo

    echo "INSERT INTO _v.patch_history(revision, branch) VALUES('$REVISION','$BRANCH');"
    echo

}
# ======================================== Functions


# process parameters
for var in "$@"
do
    lc_var=`echo $var | tr '[A-Z]' '[a-z]'` # lowercase module name
    if [ $lc_var = "-install" ]; then
        LOAD_BASE=1
    elif [ $lc_var = "-0" ]; then
        DRY_RUN=1
    fi
done

# get version information and lock patch table
lock_for_patch

# load patches. drop recreatable obejcts and make schema/data changes
load_patches

# restore recreatable objects
install_modules

# apply permissions for db objects
load_permissions

# run tests
# TODO #

# finalize
if [ $DRY_RUN -eq 1 ]; then
    echo "ROLLBACK;"
    echo
else
    echo "COMMIT;"
    echo
fi
