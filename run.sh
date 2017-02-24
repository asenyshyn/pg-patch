#!/bin/bash

set -e

readonly PROGNAME=$(basename $0)
readonly DB_PATH="$( cd "$( dirname "$0" )" && pwd )"
readonly ARGS="$@"
readonly ARGC="$#"

# default parameters
PATCH=
INSTALL=

DBUSER=''
DBHOST=''
DATABASE=''
DBPORT=''

SILENT=0

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
This is a helper script for updating and patching database

Default options could be passed to $PROGNAME with database.conf file.
Example file could be found in database.conf.default

Script will attempt to find repository information from git or hg repository.
If none is found - script will look into file repo.info (see example repo.info.example)

List of options:

 --help       - prints this message.

Connection settings:
 -h --host <host>         - target host name
 -d --database <database> - target database name
 -p --port <port>         - database server port name
 -U --user <user>         - database user

Behaviour flags
 -s --silent  - silent mode. Will not ask for actions confirmation
 -v --verbose - verbose mode. Will print all commands sent to database
 -0 --dry-run - dry run mode. Will rollback all changes in the end. Useful for testing.

Usage examples:
 ./run.sh -d demodb -h localhost -U demodb_owner -p 5432
 ./run.sh -d demodb -h localhost -U demodb_owner -p 5432 -s
 ./run.sh -c path/to/database.conf

EOF
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
    return 0
}

function read_input() {
    local default_val=$1
    local message=$2
    local input_val=$3

    if [ "$input_val" = '' ]; then
        [[ $SILENT -eq 0 ]] && read -p "$message" input_val
        input_val=${input_val:-$default_val}
    fi
    echo $input_val
}

function read_config() {
    local config=$1
    local tmp_config="/tmp/sr_db.$$.conf"

    if [ "$ARGC" == "0" ] && [ ! -f $config ] ; then
        help
        exit
    elif [ -f $config ] ; then
        # clear tmp file
        :> $tmp_config
        # remove dangerous stuff
        sed -e 's/#.*$//g;s/;.*$//g;/^$/d' $config |
            while read line
            do
                if echo $line | grep_bin -F = &>/dev/null
                then
                    echo "$line" >> $tmp_config
                fi
            done
        . $tmp_config
        rm $tmp_config
    fi
    return 0
}

function read_args() {
    local arg=

    for arg
    do
        local delim=""
        case "$arg" in
            #translate --gnu-long-options to -g (short options)
            --help)           help && exit 0;;
            --host)           args="${args}-h ";;
            --port)           args="${args}-p ";;
            --database)       args="${args}-d ";;
            --user)           args="${args}-U ";;
            --dry-run)        args="${args}-0 ";;
            --silent)         args="${args}-s ";;
            --verbose)        args="${args}-v ";;
            --test)           args="${args}-t ";;
            --roles)          args="${args}-r ";;
            --debug)          args="${args}-x ";;
            --config)         args="${args}-c ";;
            #pass through anything else
            *) [[ "${arg:0:1}" == "-" ]] || delim="\""
               args="${args}${delim}${arg}${delim} ";;
        esac
    done

    # Reset the positional parameters to the short options
    eval set -- $args

    # read parameters
    while getopts "PIc:h:d:U:p:sv0cretx" optname
    do
        case "$optname" in
            "H") help && exit 0 ;;
            "c") v_config=$OPTARG;;
            "h") v_host=$OPTARG ;;
            "d") v_db=$OPTARG ;;
            "U") v_dbuser=$OPTARG ;;
            "p") v_port=$OPTARG ;;
            "s") SILENT=1 ;;
            "v") v_verbose='-a' ;;
            "0") v_dry_run='-0' ;;
            "r") v_create_roles='-r' ;;
            "?") echo "Unknown option $OPTARG" ;;
            ":") echo "No argument value for option $OPTARG" ;;
            *) echo "Unknown error while processing options" ;;
        esac
    done
    return 0
}

function args_process() {

    # Defaults for messages
    local hostname=''
    local port='5432'
    local dbname='demodb'
    local dbuser='demodb_owner'

    # process parameters

    # server host
    v_host=$(read_input "$hostname" "Enter destination hostname [$hostname]: " ${v_host:-$DBHOST})

    # server port
    v_port=$(read_input "$port" "Enter destination port [$port]: " ${v_port:-$DBPORT})

    # database
    v_db=$(read_input "$dbname" "Enter destination database [$dbname]: " ${v_db:-$DATABASE})

    # database user
    v_dbuser=$(read_input "$dbuser" "Enter destination user [$dbuser]: " ${v_dbuser:-$DBUSER})

    cat <<EOF
You are going to apply changes to
  host:     $v_host
  database: $v_db
  username: $v_dbuser
  port:     $v_port

EOF

    [[ $SILENT -eq 0 ]] && confirm_action
    return 0
}

function run_actions() {
    local dbhost=''
    local dbport=''
    local patch_action=''
    local dbinstall=''

    if [ "$v_host" != '' ]; then
        dbhost="-h $v_host"
    fi

    if [ "$v_port" != '' ]; then
        dbport="-p $v_port"
    fi

    echo "Checking database..."
    patch_action=$(psql -tXq $dbhost $dbport -d $v_db -U $v_dbuser -f tools/sql/db_check.sql  -v appname='demodb' | tr -d '[[:space:]]')

    if [ "$patch_action" = 'I' ] ; then
        echo "Empty database. Will perform install"
        dbinstall='-install'
    elif [ "$patch_action" = 'P' ] ; then
        echo "Application and patches found. Will perform patch"
    else
        echo "Database preconditions failed."
        exit
    fi
    echo "Applying changes..."

    $DB_PATH/generate_sql.sh $dbinstall $v_dry_run |
        psql -X $v_verbose -v ON_ERROR_STOP=1 --pset pager=off $dbhost -d $v_db $dbport -U $v_dbuser 2>&1 |
        if [ "$v_verbose" = '-a' ]; then \
            cat; \
        else \
            grep_bin -E 'WARNING|ERROR|FATAL' | sed_bin 's/WARNING: //'; \
        fi

    if test ${PIPESTATUS[1]} -eq 0
    then
        echo "Done."
    else
        echo "Failed to perform actions. Check parameters that you passed."
        exit ${PIPESTATUS[1]}
    fi
    echo

    return 0
}

function main() {
    # define variables and default values
    local v_host=''
    local v_db=''
    local v_dbuser=''
    local v_port=''
    local v_verbose='-q'
    local v_dry_run=''
    local v_create_roles=''
    local v_config="$DB_PATH/database.conf"

    # get and parse arguments
    read_args $ARGS

    # get values from config file
    read_config $v_config

    # process command line parameters and config values
    args_process

    run_actions
}

main
