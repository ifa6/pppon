#! /bin/bash

LOCAL=${HOME}/.local
RUNDIR=${LOCAL}/var/run
RUNFILE=${RUNDIR}/ppp-on.sh_is_running

on () {
    touch $RUNFILE 2>/dev/null
}

off () {
    rm -f $RUNFILE 2>/dev/null
}

hay_un_script () {
    local x
    x=`ls $RUNDIR | grep ''$RUNFILE''`
    (( ${#x} > 0 ))
}

hay_conexion () {
    local x
    x=`/sbin/ifconfig ppp0 2>/dev/null | grep 'RUNNING' | wc -l`
    (( x == 1 ))
}

hay_un_chat () {
    local x
    x=`pidof chat`
    (( ${#x} > 0 ))
}

abort () {
    killall pppd 2>/dev/null && sleep 1
    off
    exit 1
}

# --

(( $# > 0 )) && abort

hay_un_script && exit 2

on
until hay_conexion
do
    killall pppd && sleep 1
    pon provider && sleep 1
    while hay_un_chat; do sleep 5; done
done
off

exit 0
