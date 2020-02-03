#!/bin/bash


# Test if is Root
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

whereami=`cd $(dirname $0);pwd`

function get_cmd()
{
    echo "$@" | while read line;do
        echo "$line" | $whereami/scan /dev/hidg0 1 1
    done
}
get_cmd "$@"
