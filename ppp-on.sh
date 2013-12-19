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
    x=`/sbin/ifconfig ppp0 2>/dev/null | grep 'RUNNING' | wc -l`
    (( x == 1 ))
}

hay_un_chat () {
    local x
    x=`pidof chat`
    (( ${#x} > 0 ))
}

abort () {
    rm -f $TESTFILE
    for prog in chat pppd ppp-on.sh
    do
        killall $prog
    done
} 2>/dev/null

# --

name=`basename $0`

case $name in

    "pppon")

        hay_un_script && exit 1

        on
        until hay_conexion
        do
            killall pppd 2>/dev/null && sleep 1
            pon provider 2>/dev/null && sleep 1
            while hay_un_chat; do sleep 5; done
        done
        off
        ;;

    "pppoff") abort ;;

    *) echo "el script sólo puede ser invocado como 'pppon' o como 'pppoff'"
       exit -1
       ;;

esac

exit 0
