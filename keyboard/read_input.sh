#!/bin/bash
###############################################
# Filename    :   read_input.sh
# Author      :   PedroQin
# Email       :   pedro.hq.qin@mail.foxconn.com
# Date        :   2020-01-31 08:46:25
# Description :   
# Version     :   1.0.0
###############################################
 

# Test if is Root
if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

whereami=`cd $(dirname $0);pwd`

dict="
\0\x4\0\0\0\0\0<-->a
\0\x5\0\0\0\0\0<-->b
\0\x6\0\0\0\0\0<-->c
\0\x7\0\0\0\0\0<-->d
\0\x8\0\0\0\0\0<-->e
\0\x9\0\0\0\0\0<-->f
\0\xa\0\0\0\0\0<-->g
\0\xb\0\0\0\0\0<-->h
\0\xc\0\0\0\0\0<-->i
\0\xd\0\0\0\0\0<-->j
\0\xe\0\0\0\0\0<-->k
\0\xf\0\0\0\0\0<-->l
\0\x10\0\0\0\0\0<-->m
\0\x11\0\0\0\0\0<-->n
\0\x12\0\0\0\0\0<-->o
\0\x13\0\0\0\0\0<-->p
\0\x14\0\0\0\0\0<-->q
\0\x15\0\0\0\0\0<-->r
\0\x16\0\0\0\0\0<-->s
\0\x17\0\0\0\0\0<-->t
\0\x18\0\0\0\0\0<-->u
\0\x19\0\0\0\0\0<-->v
\0\x1a\0\0\0\0\0<-->w
\0\x1b\0\0\0\0\0<-->x
\0\x1c\0\0\0\0\0<-->y
\0\x1d\0\0\0\0\0<-->z
\0\x1e\0\0\0\0\0<-->1
\0\x1f\0\0\0\0\0<-->2
\0\x20\0\0\0\0\0<-->3
\0\x21\0\0\0\0\0<-->4
\0\x22\0\0\0\0\0<-->5
\0\x23\0\0\0\0\0<-->6
\0\x24\0\0\0\0\0<-->7
\0\x25\0\0\0\0\0<-->8
\0\x26\0\0\0\0\0<-->9
\0\x27\0\0\0\0\0<-->0
"

delay=0.001

function press_one_key()
{
    pre_fix="$1"
    shift
    str_tmp="$@"
    for i in `seq 0 $(echo "$str_tmp"|wc -L)`;do
        c=${str_tmp:$i:1}
        [ -z "$c" ] && break
        cmd="<-->$c"
        #echo "$dict"|grep -F "$cmd"|head -1|awk -F'<-->' '{print $1}'
        keycode=`echo "$dict"|grep -F "$cmd" |head -1|awk -F'<-->' '{print $1}'`
        if [ -z "$keycode" ] ;then
            echo "Can't find '$c' 's keycode in dict!"
            exit 1
        fi
        #echo "$pre_fix""$keycode"
        echo -ne "$pre_fix""$keycode" > /dev/hidg0
        sleep $delay
        echo -ne "\0\0\0\0\0\0\0\0" > /dev/hidg0
        sleep $delay
    done
}

function get_ctl()
{
    echo "$@"|grep -Eq "[A-Z]"
    if [ $? -eq 0 ]; then
        echo "control char can't be Upper !"
        echo "$@"
    else
        press_one_key $@
    fi
}

function input_string()
{
    #echo "$@" | while read line;do
    echo -n "$@" | $whereami/scan /dev/hidg0 1 1
    #done
}

function press_enter()
{
    echo -ne "\0\0\x58\0\0\0\0\0" > /dev/hidg0
    sleep $delay
    echo -ne "\0\0\0\0\0\0\0\0" > /dev/hidg0
    sleep $delay
}

function get_cmd()
{
    #BYTE1 --
    #|--bit0: Left Control
    #|--bit1: Left Shift
    #|--bit2: Left Alt
    #|--bit3: Left GUI
    #|--bit4: Right Control
    #|--bit5: Right Shift
    #|--bit6: Right Alt
    #|--bit7: Right GUI

    # we declare the line head: CONTROL / ALT / SHIFT / GUI / STRING / DELAY / ENTER / EXIT 
    echo "$@" | while read line;do
        case ${line:0:3} in
            CON)
            prefix="\x1"
            press_one_key "$prefix" "${line#* }"
            #press_enter
            ;;
            ALT)
            prefix="\x4"
            press_one_key "$prefix" "${line#* }"
            #press_enter
            ;;
            SHI)
            prefix="\x2"
            press_one_key "$prefix" "${line#* }"
            #press_enter
            ;;
            GUI)
            prefix="\x08"
            press_one_key "$prefix" "${line#* }"
            ;;
            REM)
            continue
            ;;
            STR)
            input_string "${line#* }"
            ;;
            ENT)
            press_enter
            ;;
            DEL)
            sleep "${line#* }"
            ;;
            EXI)
            return 
            ;;
            *)
            input_string "${line}"
            ;;
        esac
    done
}

function console_mode()
{
    head_str="input mode"
    while ((1));do

        read -p "$head_str > " input_str
        [ -z "$input_str" ] && get_cmd ENTER && continue
        [ "$input_str" == "byebye" ] && break        
        get_cmd "$input_str"
        if [ "${input_str:0:3}" != "CON" ] &&[ "${input_str:0:3}" != "ALT" ] && [ "${input_str:0:3}" != "SHI" ] && [ "${input_str:0:3}" != "GUI" ] && [ "${input_str:0:3}" != "ENT" ] && [ "${input_str:0:3}" != "DEL" ] && [ "${input_str:0:3}" != "EXI" ] ;then
           get_cmd ENTER
        fi

    done

}

case $1 in 
    -f|--file)
    shift
    file="${1}"
    [ ! -f "$file" ] && echo "Can't find file: $file !" && exit 1
    get_cmd "$(cat $file)"
    ;;
    
    -c|--console)
    console_mode
    ;;

    *)
    echo "Default mode : console "
    console_mode
    ;;
esac
