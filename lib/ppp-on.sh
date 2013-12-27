#! /bin/bash -x

# Códigos de terminación
OK=0
SCRIPT=1
OFFLINE=2
BUSY=3
ABORT=4
NAME_ERROR=-1

# == FUNCIONES ==

# Comprobar si se está ejecutando un script
PIDDIR=${HOME}/.local/var/run
PIDFILE=${PIDDIR}/ppp-on.sh_is_running

on () {
    touch $PIDFILE 2>/dev/null
}

off () {
    rm -f $PIDFILE 2>/dev/null
}

hay_un_script () {
    [[ -e $PIDFILE ]]
}

# -- MODEM --
# Los mensajes que emite wvdial cuando tantea el estado del modem
MODEM_OFFLINE="Modem not responding"
MODEM_BUSY="Device or resource busy"

modem_offline () {
    local x
    x=`wvdial 2>&1 | grep "$MODEM_OFFLINE"`
    (( ${#x} > 0 ))
}

modem_ocupado () {
    local x
    x=`wvdial 2>&1 | grep "$MODEM_BUSY"`
    (( ${#x} > 0 ))
}
# --
# Saber si hay una conexión en curso o si hay un intento de conectar.
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
# --
# ABORT
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

        hay_un_script && exit $SCRIPT
        modem_offline && exit $OFFLINE
        modem_ocupado && exit $BUSY

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
        hay_un_chat && { abort; exit $ABORT; }
        hay_conexion && poff -a
        killall pppon
        ;;

    *) echo "el script sólo puede ser invocado como 'pppon' o como 'pppoff'"
       exit $NAME_ERROR
       ;;

esac

exit $OK
