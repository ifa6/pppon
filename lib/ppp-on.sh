#! /bin/bash -x

# Códigos de terminación
OK=0             # Todo fue bien
SCRIPT=1         # Hay otro pppon intentando conectar
OFFLINE=2        # Modem fuera de línea
BUSY=3           # Modem ocupado
ABORT=4          # Se activa pppoff cuando pppon ejecutaba un chat
NAME_ERROR=-1    # Sólo se puede llamar como pppon o pppoff

# ==== >>> FUNCIONES <<<
# Comprobar si se está ejecutando un pppon
hay_un_script () {
    local x
    x=`pidof pppon 2>/dev/null`
    (( ${#x} > 0 ))
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
# --
# -- MYIP --
# logear las direcciones IP local y remota así como las direcciones
# de los DNS primario y secundario.
IPLOGFILE=$HOME/.local/var/log/myip

getIPs () {
    sudo cat /var/log/messages \
        | grep 'pppd\['`pidof pppd`'\]:.*address'
}

logIPs () {
    echo "--------------------------------------"
    getIPs | head -n 1 - | sed 's/\(.*:[0-9]\+\).*/\1/'
    echo "==============="
    getIPs | sed '{ s/.*\]://; s/IP/   IP /; }'
    echo "--------------------------------------"
} >> $IPLOGFILE
# --
# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

name=`basename $0`

case $name in

    "pppon")

        hay_un_script && exit $SCRIPT
        modem_offline && exit $OFFLINE
        modem_ocupado && exit $BUSY

        until hay_conexion
        do
            killall pppd && sleep 1
            pon provider && sleep 1
            while hay_un_chat; do sleep 5; done
        done

        logIPs
        ;;

    "pppoff")

        hay_un_chat && { abort; exit $ABORT; }
        hay_conexion && poff -a
        killall pppon
        ;;

    *) echo "el script sólo puede ser invocado como 'pppon' o como 'pppoff'"
       exit $NAME_ERROR
       ;;

esac

exit $OK
