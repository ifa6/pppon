#! /bin/bash -x

RUNDIR=${HOME}/.local/var/run
RUNFILE=${RUNDIR}/ppp-on.sh_is_running

on () {
    touch $RUNFILE 2>/dev/null
}

off () {
    rm -f $RUNFILE 2>/dev/null
}

hay_un_script () {
    [[ -e $RUNFILE ]]
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
    rm -f $RUNFILE
    for prog in chat pppd ppp-on.sh
    do
        killall $prog
    done
} 2>/dev/null

# --

(( $# > 0 )) && abort

hay_un_script && exit 2

on
until hay_conexion
do
    killall pppd 2>/dev/null && sleep 1
    pon provider 2>/dev/null && sleep 1
    while hay_un_chat; do sleep 5; done
done
off

exit 0
