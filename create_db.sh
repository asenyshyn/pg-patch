#!/bin/bash

#help
function help {
    cat <<EOF

    This is help for $(basename $0) scrpit
    Script generates roles and database create statements
     -d <database name> - pass a database name
     -r - is flag is passed - create roles/users statements will be included
     -e - if passed, encoding settings will not be included into DDL

EOF
}

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

DBNAME=''
ADDROLES=0
BASE_PATH="$( cd "$( dirname "$0" )" && pwd )"
ENCODING=1

if [ "$#" == "0" ]; then
    exit
fi

#read parameters
while getopts "Hrd:e" optname
do
    case "$optname" in
        "H")
            help
            exit
            ;;
        "r")
            ADDROLES=1
            ;;
        "d")
            DBNAME=$OPTARG
            ;;
        "e")
            ENCODING=0
            ;;
        "?")
            echo "Unknown option $OPTARG"
            ;;
        ":")
            echo "No argument value for option $OPTARG"
            ;;
        *)
            echo "Unknown error while processing options"
            ;;
    esac
done

if [ "$DBNAME" = '' ]; then
    exit
fi

# create users
if [ $ADDROLES -eq 1 ]; then
    sed_bin 's/^\xEF\xBB\xBF//' $BASE_PATH/init/default_users.sql
    echo
fi

# create database
echo "CREATE DATABASE $DBNAME"
echo "  WITH OWNER = postgres"
echo "       ENCODING = 'UTF8'"
echo "       TABLESPACE = pg_default"
if [ $ENCODING -eq 1 ]; then
    echo "       LC_COLLATE = 'en_US.UTF-8'"
    echo "       LC_CTYPE = 'en_US.UTF-8'"
fi;
echo "       CONNECTION LIMIT = -1"
echo "       TEMPLATE = template0;"
echo

# etc
