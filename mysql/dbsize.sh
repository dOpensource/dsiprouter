#!/usr/bin/env bash

# Usage info
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Usage: $0 [<dbname>]"
    exit 1
fi

# Get size of database
if (( $# > 0 )); then
    DBNAME="$1"
    mysql -e "\
        SELECT table_schema 'DB Name',\
        sum( data_length + index_length ) / 1024 / 1024 'DB Size in MB',\
        sum( data_free ) / 1024 / 1024 'Free Space in MB'\
        FROM information_schema.TABLES\
        WHERE table_schema='${DBNAME}'\
        GROUP BY table_schema;"
else
    mysql -e "\
        SELECT table_schema 'DB Name',\
        sum( data_length + index_length ) / 1024 / 1024 'DB Size in MB',\
        sum( data_free )/ 1024 / 1024 'Free Space in MB'\
        FROM information_schema.TABLES\
        GROUP BY table_schema;"
fi

exit 0




