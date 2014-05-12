#! /bin/bash

# ------------------------------------------------------------------------------
#    pppon - Gestiona la conexión con el ISP usando un modem y pppd.
#
#    Copyright (C) 2013, 2014 José Lorenzo Nieto Corral.
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
# ------------------------------------------------------------------------------


# Códigos de terminación
OK=0             # Todo fue bien
SCRIPT=1         # Hay otro pppon intentando conectar
OFFLINE=2        # Modem fuera de línea
BUSY=3           # Modem ocupado
ABORT=4          # Se activa pppoff cuando pppon ejecutaba un chat
NAME_ERROR=-1    # Sólo se puede llamar como pppon o pppoff

# >>> FUNCIONES <<<
# Comprobar si se está ejecutando un pppon
hay_un_script () {
    local x
    x=`pidof pppon 2>/dev/null`
    (( ${#x} > 0 ))
}

# **MODEM**
# Los mensajes que emite wvdial cuando tantea el estado del modem
MODEM_OFFLINE="Modem not responding"
modem_offline () {
    local x
    x=`wvdial 2>&1 | grep "$MODEM_OFFLINE"`
    (( ${#x} > 0 ))
}

MODEM_BUSY="Device or resource busy"
modem_ocupado () {
    local x
    x=`wvdial 2>&1 | grep "$MODEM_BUSY"`
    (( ${#x} > 0 ))
}
# --
# Saber si hay una conexión activa.
hay_conexion () {
    local x
    x=`/sbin/ifconfig ppp0 2>/dev/null`
    (( ${#x} > 0 ))
}

# Saber si hay un intento de conexión en curso.
hay_un_chat () {
    local x
    x=`pidof chat 2>/dev/null`
    (( ${#x} > 0 ))
}
# --
# cuando activamos pppoff y hay un chat en curso
abort () {
    for prog in chat pppd pppon
    do
        killall $prog
    done
} 2>/dev/null
# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# **MYIP**
# logear las direcciones IP local y remota así como las direcciones
# de los DNS primario y secundario.
MYIPLIB=$HOME/.local/lib/myip.lib
logips () {
    source $MYIPLIB
    logIPs
}
echoips () {
    source $MYIPLIB
    echoIPs
}
allips () {
    source $MYIPLIB
    allIPs
}
lastips () {
    source $MYIPLIB
    lastIPs "$@"
}
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

        logips
        ;;

    "pppoff")

        hay_un_chat && { abort; exit $ABORT; }
        hay_conexion && poff -a
        killall pppon
        ;;

    "myip")

        echoips
        ;;

    "allips")

        allips
        ;;

    "lastips")

        lastips "$@"
        ;;

    *) cat <<@
 El script sólo puede ser invocado como:

    'pppon', 'pppoff', 'myip', 'allips' o 'lastips'.
@
       exit $NAME_ERROR
       ;;

esac

exit $OK
