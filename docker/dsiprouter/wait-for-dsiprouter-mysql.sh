#!/bin/sh
# wait-for-dsiprouter-mysql.sh

set -e

host="$1"
shift
cmd="$@"

until python ./gui/dsiprouter.py runserver; do
  >&2 echo "dSIPRouter MySQL is unavailable - can't start - sleeping"
  sleep 1
done

>&2 echo "dSIPRouter MySQL is up - started dSIPRouter"
