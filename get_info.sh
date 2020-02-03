#!/bin/bash
###############################################
# Filename    :   get_info.sh
# Author      :   PedroQin
# Email       :   pedro.hq.qin@mail.foxconn.com
# Date        :   2020-01-21 10:56:25
# Description :   
# Version     :   1.0.0
###############################################
 

whereami=`cd $(dirname $0);pwd`

# show message in green
function green_message()
{
    #tput bold
    #echo -ne "\033[32m$@\033[0m"
    echo -ne "$@"
    #tput sgr0
    echo
}

#show message in yellow
function yellow_message()
{
    #tput bold
    #echo -ne "\033[33m$@\033[0m"
    echo -ne "$@"
    #tput sgr0
    echo
}

# show message in red
function red_message()
{
    #tput bold
    #echo -ne "\033[31m$@\033[0m"
    echo -ne "$@"
    #tput sgr0
    echo
}

# print description and then run it
function print_run()
{
    if [ $# -eq 1 ];then
        green_message "$1"
        eval "$1"
    elif [ $# -eq 2 ];then
        green_message "$1"
        eval "$2"
    else
        return 1
    fi
}

function u_disk_mode()
{
    echo "keyboard, U disk, ethter Mode are mutual exclusion"
    print_run "systemctl disable enable_hid.service"
    #print_rnn "echo 'console=serial0,115200 console=tty1 root=PARTUUID=6c586e13-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait modules-load=dwc2,g_mass_storage' > /boot/cmdline.txt"
    print_run 'cmdline=`cat /boot/cmdline.txt|sed "s/modules-load=dwc2[a-z_,]\{0,20\}/modules-load=dwc2,g_mass_storage/g"`; echo "$cmdline" > /boot/cmdline.txt'
}

function ether_mode()
{
    echo "keyboard, U disk, ethter Mode are mutual exclusion"
    print_run "systemctl disable enable_hid.service"
    #print_run "echo 'console=serial0,115200 console=tty1 root=PARTUUID=6c586e13-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait modules-load=dwc2,g_ether' > /boot/cmdline.txt"
    print_run 'cmdline=`cat /boot/cmdline.txt|sed "s/modules-load=dwc2[a-z_,]\{0,20\}/modules-load=dwc2,g_ether/g"`; echo "$cmdline" > /boot/cmdline.txt'

}

function change_mode()
{
    #if cat /proc/cmdline |grep -q g_ether; then
    if cat /boot/cmdline.txt |grep -q g_ether; then
        echo "keyboard, U disk, ethter Mode are mutual exclusion"
        print_run "systemctl disable enable_hid.service"
       print_run 'cmdline=`cat /boot/cmdline.txt|sed "s/modules-load=dwc2[a-z_,]\{0,20\}/modules-load=dwc2,g_mass_storage/g"`; echo "$cmdline" > /boot/cmdline.txt'
        #print_run "echo 'console=serial0,115200 console=tty1 root=PARTUUID=6c586e13-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait modules-load=dwc2,g_mass_storage' > /boot/cmdline.txt"
    else 
        echo "keyboard, U disk, ethter Mode are mutual exclusion"
        print_run "systemctl disable enable_hid.service"
        print_run 'cmdline=`cat /boot/cmdline.txt|sed "s/modules-load=dwc2[a-z_,]\{0,20\}/modules-load=dwc2,g_ether/g"`; echo "$cmdline" > /boot/cmdline.txt'
        #print_run "echo 'console=serial0,115200 console=tty1 root=PARTUUID=6c586e13-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait modules-load=dwc2,g_ether' > /boot/cmdline.txt"
    fi

}

function flash_u_disk()
{
    mode=`cat /proc/cmdline |grep -oE 'modules-load=[0-9a-z,_]+'|cut -d= -f2`
    if [ "$mode" != "dwc2,g_mass_storage" ];then
        red_message "Current MODE: $mode ,Pls ChangeMode first to dwc2,g_mass_storage!"
        return 1
    else
        echo "keyboard, U disk, ethter Mode are mutual exclusion"
        print_run "systemctl disable enable_hid.service"
        print_run 'rmmod g_mass_storage;sleep 1'
        print_run 'modprobe g_mass_storage file=/home/my_u_disk.bin removable=1 dVendor=0x0781 idProduct=0x5572 bcdDevice=0x011a iManufacturer="SanDisk" iProduct="Cruzer Switch" iSerialNumber="1234567890"'
    fi
}

function getwlancfg_etc2mnt()
{
    mount |grep -q "/home/my_u_disk.bin"
    if [ $? -ne 0 ] ;then
        [ ! -f "/home/my_u_disk.bin" ] && echo "Can't find the file: /home/my_u_disk.bin !" && exit 1
        print_run "mount /home/my_u_disk.bin /mnt"
        [ $? -ne 0 ] && echo "mount /home/my_u_disk.bin to /mnt failed !" && exit 2
    fi
    print_run "[ ! -d /mnt/OS_setting ] && mkdir /mnt/OS_setting ; cp /etc/wpa_supplicant/wpa_supplicant.conf /mnt/OS_setting/;sync"

}

function getwlancfg_mnt2etc()
{
    mount |grep -q "/home/my_u_disk.bin"
    if [ $? -ne 0 ] ;then
        [ ! -f "/home/my_u_disk.bin" ] && echo "Can't find the file: /home/my_u_disk.bin !" && exit 1
        print_run "mount /home/my_u_disk.bin /mnt"
        [ $? -ne 0 ] && echo "mount /home/my_u_disk.bin to /mnt failed !" && exit 2
    fi
    print_run "[ -f /mnt/OS_setting/wpa_supplicant.conf ] && cp /mnt/OS_setting/wpa_supplicant.conf /etc/wpa_supplicant;sync"

}

function export_log()
{
    mount |grep -q "/home/my_u_disk.bin"
    if [ $? -ne 0 ] ;then
        [ ! -f "/home/my_u_disk.bin" ] && echo "Can't find the file: /home/my_u_disk.bin !" && exit 1
        print_run "mount /home/my_u_disk.bin /mnt"
        [ $? -ne 0 ] && echo "mount /home/my_u_disk.bin to /mnt failed !" && exit 2
    fi
    print_run "[ ! -d /mnt/log ] && mkdir /mnt/log ; cp "$@" /mnt/log;sync"
    print_run "[ ! -d /mnt/log ] && mkdir /mnt/log ; cp create_ap_log_* /mnt/log/ 2>/dev/null ;sync"

}

function pi_as_keyboard()
{

    if systemctl is-enabled enable_hid.service > /dev/null 2>&1 ;then
        print_run "systemctl disable enable_hid.service"
    else
        echo "keyboard, U disk, ethter Mode are mutual exclusion"
        print_run 'cmdline=`cat /boot/cmdline.txt|sed "s/modules-load=dwc2[a-z_,]\{0,20\}/modules-load=dwc2/g"`; echo "$cmdline" > /boot/cmdline.txt'
        #print_run "echo 'console=serial0,115200 console=tty1 root=PARTUUID=6c586e13-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait modules-load=dwc2' > /boot/cmdline.txt"
        print_run "systemctl enable enable_hid.service"
    fi
    
}

function get_status()
{
    echo "IP:         `ifconfig wlan0 | awk '/inet / {print $2}'`"
    echo "Loadavg:    `cat /proc/loadavg`"
    echo "Temp:       `echo "scale=3;$(cat /sys/class/thermal/thermal_zone0/temp)/1000" | bc`"
    echo "Mode:       `cat /proc/cmdline |grep -oE 'modules-load=[0-9a-z,_]+'|cut -d= -f2`"
    echo "Pi_as_kbd:  `systemctl is-enabled enable_hid.service`"
    echo "Pi_as_kbd status: `[ -f /tmp/enable_hid.lock ] && echo "running" || echo "stop"` "

}

function enable_ap()
{
    AP_name="SecretAP"
    AP_pwd="12345678"
    pid1=`ps aux|grep  "create_ap -n wlan0"|grep -v grep`
    pid2=`ps aux|grep "iwlan0"|grep -v grep`
    if [ ! -z "$pid1" -a -z "$pid2" ];then
        green_message "It is AP mode now,skip..."
        return 0
    fi
    kill "$(ps aux|grep "iwlan0"|head -1|awk '{print $2}')" > /dev/null 2>&1
    DATE=`date +"%Y%m%d%H%M%S"`
    print_run "nohup create_ap -n wlan0 $AP_name $AP_pwd > /tmp/create_ap_log_${DATE}.log 2>&1 &"
}



case $1 in

    Get_Status)
    get_status
    ;;

    ChangeMode)
    change_mode
    yellow_message "Restart and take effect"
    ;;

    U-DiskMode)
    u_disk_mode
    yellow_message "Restart and take effect"
    ;;

    EtherMode)
    ether_mode
    yellow_message "Restart and take effect"
    ;;

    Flash_U_Disk)
    flash_u_disk
    ;;

    Re-GetIP)
    pid2=`ps aux|grep "iwlan0"|grep -v grep`
    # if -z pid2 , current mode maybe AP mode,so ,can't release ip in AP mode
    [ ! -z "$pid2" ] && print_run "dhclient -r wlan0;dhclient;ifconfig wlan0 | awk '/inet / {print \$2}'"
    print_run "ifconfig|grep 'inet '|awk '{print \$2}'"
    ;;

    CatCmdline)
    green_message "config file: "
    print_run "cat /boot/cmdline.txt"
    green_message "current file: "
    print_run "cat /proc/cmdline"
    ;;

    CatWlanCfg)
    print_run "cat /etc/wpa_supplicant/wpa_supplicant.conf"
    ;;

    GetWlanCfg_mnt2etc)
    getwlancfg_mnt2etc
    #print_run "cp /etc/wpa_supplicant/wpa_supplicant.conf /boot;sync"
    yellow_message "Restart and take effect"
    ;;

    GetWlanCfg_etc2boot)
    print_run "cp /etc/wpa_supplicant/wpa_supplicant.conf /boot;sync"
    yellow_message "Restart and take effect"
    ;;

    GetWlanCfg_etc2mnt)
    getwlancfg_etc2mnt
    ;;
    
    Export_log)
    shift
    export_log "$@"
    ;;

    PI-as-keyboard)
    pi_as_keyboard
    yellow_message "Restart and take effect"
    ;;

    EnableAP)
    enable_ap
    ;;

    *)
    red_message "Can't find function: $1"
    ;;
esac
