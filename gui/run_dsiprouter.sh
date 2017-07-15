#!/bin/bash
# Uncomment if you want to debug this script
set -x

REQ_PYTHON_VER=3.6

# Uncomment and set this variable to an explicit Python executable file name
# If set, the script will not try and find a Python version with 3.5 as the major release number
PYTHON_CMD=/usr/bin/python3.4

function isPythonInstalled {


possible_python_versions=`find / -name "python$REQ_PYTHON_VER" -type f -executable  2>/dev/null`
for i in $possible_python_versions
do
    ver=`$i -V 2>&1`
    echo $ver | grep $REQ_PYTHON_VER >/dev/null
    if [ $? -eq 0 ]; then
        PYTHON_CMD=$i
        return
    fi
done

#Required version of Python is not found.  So, tell the user to install the required version
    echo -e "\nPlease install at least python version $REQ_PYTHON_VER\n"
    exit

}

if [ -z ${PYTHON_CMD+x} ]; then
    isPythonInstalled
fi

#if [ `ps -ef | grep dsiprouter | wc -l` -ge 2 ]; then
#    echo "dSIPRouter is already running.  You might want to kill that version first :-) -Love Ya"
#    exit
#fi

$PYTHON_CMD -m pip install -r requirements.txt
nohup $PYTHON_CMD dsiprouter.py runserver -h 0.0.0.0 -p 5000 >/dev/null 2>&1 &
#nohup $PYTHON_CMD dsiprouter.py runserver -h 0.0.0.0 -p 5000

