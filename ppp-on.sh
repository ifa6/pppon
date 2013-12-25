#! /bin/bash -x

TESTDIR=${HOME}/.local/var/run
TESTFILE=${TESTDIR}/ppp-on.sh_is_running

on () {
    touch $TESTFILE 2>/dev/null
}

off () {
    rm -f $TESTFILE 2>/dev/null
}

hay_un_script () {
    [[ -e $TESTFILE ]]
}

hay_conexion () {
    local x
    x=`/sbin/ifconfig ppp0 2>/dev/null`
    (( ${#x} > 0 ))
}

hay_un_chat () {
    local x
    x=`pidof chat 2>/dev/null`
    (( ${#x} > 0 ))
}

abort () {
    for prog in chat pppd pppon
    do
        killall $prog
    done
} 2>/dev/null

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

name=`basename $0`

case $name in

    "pppon")

        hay_un_script && exit 1

        on
        until hay_conexion
        do
            killall pppd && sleep 1
            pon provider && sleep 1
            while hay_un_chat; do sleep 5; done
        done
        off
        ;;

    "pppoff")

        off
        hay_un_chat && { abort; exit 2; }
        hay_conexion && poff -a
        killall pppon
        ;;

    *) echo "el script sólo puede ser invocado como 'pppon' o como 'pppoff'"
       exit -1
       ;;

esac

exit 0
