#!/bin/bash

set -e

readonly PROGNAME=$(basename $0)
readonly ARGS="$@"
readonly ARGC="$#"

# default parameters
PATCH=0
INSTALL=0
INSTALL_ARG=''
ENCODING_AGR=''

DBUSER=''
DBHOST=''
DATABASE=''
DBPORT=5432
DBPORT_ARG=''

SILENT=0
VERBOSE='-q'
DRY_RUN=''

CREATEDB=0
CREATEROLES=''

function grep_bin() {
    if [[ ${OSTYPE//[0-9.]} == "solaris" ]]; then
        ggrep "$@"
    else
        grep "$@"
    fi
}

function sed_bin() {
    if [[ ${OSTYPE//[0-9.]} == "solaris" ]]; then
        gsed "$@"
    else
        sed "$@"
    fi
}

function help {
    cat <<EOF

This is help for $PROGNAME script
This is a helper script for updating and patching Postgresql database

Default options could be passed to $PROGNAME with config.cfg file.
Example file could be found in config.cfg.default

Script will attempt to find repository information from git or hg repository.
If none is found - script will look into file repo.info (see example repo.info.example)

List of options:

 --help       - prints this message.

Script flags:
 -P --patch   - patch database
 -I --install - install database. Will install versioning and all patches.

Connection settings:
 -h --host <host>         - target host name
 -d --database <database> - target database name
 -p --port <port>         - database server port name
 -U --user <user>         - database user

Behaviour flags
 -s --silent  - silent mode. Will not ask for actions confirmation
 -v --verbose - verbose mode. Will print all commands sent to database
 -0 --dry-run - dry run mode. Will rollback all changes in the end. Useful for testing.

Database and roles flags:
 -C --create     - create target database. Action will be performed with
                   user 'postgres' no matter what user you provide
 -r --roles      - create roles for demodb database if totally new installation.
                   Action is performed as user 'postgres'
 -e --enc-ignore - ignore encoding settings in CREATE DATABASE statement.

Usage examples:
 Create new database 'demodb_dev':
 ./run.sh -I -d demodb_dev -h localhost -U postgres -p 5432 -C

 Patch database 'demodb_dev':
 ./run.sh -P -d demodb_dev -h localhost -U postgres -p 5432 -s

 Test if your changes apply succesfuly:
 ./run.sh -P -d demodb_dev -h localhost -U postgres -p 5432 -s -0

EOF
}

startup() {
    if [ "$ARGC" == "0" ] && [ ! -f config.cfg ] ; then
        help
        exit
    elif [ -f config.cfg ] ; then
        . config.cfg
        DBPORT_ARG="-p $DBPORT"
    fi
}

function confirm_action {
    while true; do
        read -p "Do you want to continue? [y/n]: " ans
        case $ans in
            [Yy]* )
                break;;
            [Nn]* )
                exit;;
            * )
                echo "Please answer yes on no."
        esac
    done
}

args_parse() {
    local arg=
    for arg
    do
        local delim=""
        case "$arg" in
            #translate --gnu-long-options to -g (short options)
            --help)           help && exit 0;;
            --patch)          args="${args}-P ";;
            --install)        args="${args}-I ";;
            --host)           args="${args}-h ";;
            --port)           args="${args}-p ";;
            --database)       args="${args}-d ";;
            --user)           args="${args}-U ";;
            --dry-run)        args="${args}-0 ";;
            --silent)         args="${args}-s ";;
            --verbose)        args="${args}-v ";;
            --test)           args="${args}-t ";;
            --create)         args="${args}-C ";;
            --roles)          args="${args}-r ";;
            --enc-ignore)     args="${args}-e ";;
            --debug)          args="${args}-x ";;
            --config)         args="${args}-c ";;
            #pass through anything else
            *) [[ "${arg:0:1}" == "-" ]] || delim="\""
                args="${args}${delim}${arg}${delim} ";;
        esac
    done

    #Reset the positional parameters to the short options
    eval set -- $args

    # read parameters
    while getopts "PIh:d:U:p:sv0creCtx" optname
    do
        case "$optname" in
            "H")
                help
                exit
                ;;
            "P")
                PATCH=1
                ;;
            "I")
                INSTALL=1
                INSTALL_ARG='-install'
                ;;
            "h")
                DBHOST=$OPTARG
                ;;
            "d")
                DATABASE=$OPTARG
                ;;
            "U")
                DBUSER=$OPTARG
                ;;
            "p")
                DBPORT=$OPTARG
                DBPORT_ARG="-p $DBPORT"
                ;;
            "M")
                MODULE=$OPTARG
                ;;
            "s")
                SILENT=1
                ;;
            "v")
                # echo all input from script
                VERBOSE='-a'
                ;;
            "0")
                DRY_RUN='-0'
                ;;
            "C")
                CREATEDB=1
                ;;
            "r")
                CREATEROLES='-r'
                ;;
            "e")
                ENCODING_AGR='-e'
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

    return 0
}

args_process() {
    # process parameters

    #do not use patch and install options at the same time
    if [ $PATCH -eq 1 ] && [ $INSTALL -eq 1 ]; then
        echo "Please decide do you want to patch or install."
        exit
    fi

    if [ $INSTALL -ne 1 ] && [ $CREATEDB -eq 1 ]; then
        echo "Cannot create new database if install is not performed."
        exit
    fi

    #if none was supplied - patch db
    if [ $PATCH -eq 0 ] && [ $INSTALL -eq 0 ]; then
        echo "Patching database (no action was specified)."
        confirm_action
        PATCH=1
    fi

    # server host
    if [ "$DBHOST" = '' ]; then
        if [ $SILENT -eq 0 ]; then
            read -p "Enter destination hostname [127.0.0.1]: " DBHOST
            DBHOST=${DBHOST:-127.0.0.1}
        else
            DBHOST='127.0.0.1'
        fi
    fi

    # database
    if [ "$DATABASE" = '' ]; then
        if [ $SILENT -eq 0 ]; then
            read -p "Enter destination database [demodb]: " DATABASE
            DATABASE=${DATABASE:-demodb}
        else
            DATABASE='demodb'
        fi
    fi

    # database user
    if [ "$DBUSER" = '' ]; then
        if [ $SILENT -eq 0 ]; then
            read -p "Enter database username [postgres]: " DBUSER
            DBUSER=${DBUSER:-postgres}
        else
            DBUSER='postgres'
        fi
    fi

    # write parameters back to user and ask for confirmation
    if [ $INSTALL -eq 1 ]; then
        echo "You are going to INSTALL database to database $DATABASE at host $DBHOST"
    fi

    if [ $PATCH -eq 1 ]; then
        echo "You are going to PATCH database $DATABASE at host $DBHOST"
    fi

    cat <<EOF
  Using host:     $DBHOST
  Using database: $DATABASE
  Using username: $DBUSER
  Using port:     $DBPORT

EOF

    if [ $SILENT -eq 0 ]; then
        confirm_action
    fi
}

run_actions() {
    # create target database
    if [ $CREATEDB -eq 1 ]  && [ $INSTALL -eq 1 ]; then
        echo "You are going to create database $DATABASE on host $DBHOST."
        if [ $SILENT -eq 0 ]; then
            confirm_action
        fi
        echo "Creating database $DATABASE ..."
        ./create_db.sh -d $DATABASE $CREATEROLES $ENCODING_AGR \
            | psql -X $VERBOSE -v ON_ERROR_STOP=1 --pset pager=off -h $DBHOST $DBPORT_ARG -U postgres -d postgres

        if test $? -eq 0
        then
            echo "Done."
        else
            echo "Failed to create database."
            exit
        fi
        echo
    fi

    # install versioning if INSTALL
    if [ $INSTALL -eq 1 ]; then
        echo "Installing versioning..."
        psql -X $VERBOSE -v ON_ERROR_STOP=1 --pset pager=off -h $DBHOST -d $DATABASE $DBPORT_ARG -U $DBUSER -f tools/install_versioning.sql
        if test $? -eq 0
        then
            echo "Done."
        else
            echo "Failed to install versioning"
            exit
        fi
        echo
        echo "Installing..."
    fi

    # Patch
    if [ $PATCH -eq 1 ]; then
        echo "Patching..."
    fi

    # do the magic
    ./generate_sql.sh $INSTALL_ARG $DRY_RUN |
        psql -X $VERBOSE -v ON_ERROR_STOP=1 --pset pager=off -h $DBHOST -d $DATABASE $DBPORT_ARG -U $DBUSER 2>&1 |
        if [ "$VERBOSE" = '-a' ]; then \
            cat; \
        else \
            grep_bin -E 'WARNING|ERROR|FATAL' | sed_bin 's/WARNING: //'; \
        fi

    if test ${PIPESTATUS[1]} -eq 0
    then
        echo "Done."
    else
        echo "Failed to perform actions. Check parameters that you passed."
        exit
    fi
    echo

}

main() {
    startup
    args_parse $ARGS
    args_process
    run_actions
}

main
