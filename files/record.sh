#!/bin/bash

declare -i timeout=65    # default timeout in seconds.

Kill='/bin/kill'
split_line='-------------------------------------------------------------------------------'

success_msg='status OK'  

ext_prg="arecord "$1
( ${ext_prg} )
cPID=$!                        
sleep 5                       
((timeout-=5))

status=0
if [[ ${timeout} -gt 0 ]]; then
    while [[ $( ps | grep -o -G "^${cPID}"; ) -eq ${cPID} && ${status} -eq 0 ]]; do
        status=$((timeout-- ? 0 : 1)); sleep 1
    done
fi

if [[ ${status} -eq 1 ]]; then
    eval '${Kill} -9 ${cPID}' &>/dev/null;  
    echo "${split_line}"
    echo `basename $0`": Timeout occured, record saved."
    echo "Process(${cPID}): ${ext_prg}"
    echo "was killed because of timeout."
    echo "${split_line}"
    exit 1
else
    echo "${split_line}"
    echo -en "Process(${cPID}): ${ext_prg}\nterminate by itself successfully.\n"
    rc=$(cat ${ftmp} | awk "/${success_msg}/"'{print $2}')
    if [[ -z "${rc}" ]]; then
        echo "${ext_prg}: ERR: no success code returned!!!"
        exit 1
    else
        echo "${ext_prg}: return success code!!!"
    fi
    echo "${split_line}"
fi

exit 0
