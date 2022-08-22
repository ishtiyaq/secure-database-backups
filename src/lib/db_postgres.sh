#!/usr/bin/env bash

set -euo pipefail

#/ Retrieve the list of all databases, excluding system databases
#/
#/ @usage var="$(psql_command "localhost" "5432" "root" "root" "SELECT datname FROM pg_database;")"
#/
#/ @param $1 Host
#/ @param $2 Port
#/ @param $3 User
#/ @param $4 Password
#/ @param $5 Command
#/ @return Prints the command result
psql_command () {
    if [ "$#" -ne 5 ]; then
        echo "5 arguments required, $# provided"
        exit 1
    fi

    PGPASSWORD="$4" psql --host "$1" --port "$2" --username "$3" -q -A -t -c "$5" 
}

#/ Retrieve a space-separated list of all databases, excluding system databases
#/
#/ @usage var="$(get_databases_list "localhost" "5432" "root" "root")"
#/
#/ @param $1 Host
#/ @param $2 Port
#/ @param $3 User
#/ @param $4 Password
#/ @return Prints the result
get_databases_list () {
    if [ "$#" -ne 4 ]; then
        echo "4 arguments required, $# provided"
        exit 1
    fi

    PGPASSWORD="$4" psql_command "$1" "$2" "$3" "$4" "SELECT datname FROM pg_database;" \
        | grep -Ev "postgres|template(0|1)" \
        | tr '\n' ' ' \
        | sed 's/[ \r\n]*$//'
}

#/ Dump a single database in /tmp/backup/
#/
#/ @usage dump_database "localhost" "5432" "root" "root" "database_name"
#/
#/ @param $1 Host
#/ @param $2 Port
#/ @param $3 User
#/ @param $4 Password
#/ @param $5 Database name
dump_database () {
    if [ "$#" -ne 5 ]; then
        echo "5 arguments required, $# provided"
        exit 1
    fi

    mkdir -p "/tmp/backup"
    PGPASSWORD="$4" pg_dump --host "$1" --port "$2" --username "$3" "$5" 2>/dev/null > "/tmp/backup/$5.sql"
}

#/ Wait for database to be reachable
#/
#/ @usage wait_for_database "localhost" "5432" "root" "root" "60"
#/
#/ @param $1 Host
#/ @param $2 Port
#/ @param $3 User
#/ @param $4 Password
#/ @param $5 Max attempts
wait_for_database () {
    if [ "$#" -ne 5 ]; then
        echo "5 arguments required, $# provided"
        exit 1
    fi

    attempts=$5

    until [ "$attempts" -eq 0 ] || database_error=$(PGPASSWORD="$4" PGCONNECT_TIMEOUT=1 psql --host "$1" --port "$2" --username "$3" -c "SELECT 1" 2>&1); do
        sleep 1
        attempts=$((attempts - 1))
    done

    if [ $attempts -eq 0 ]; then
        echo "The database is not reachable: $database_error"
        exit 1
    fi
}
