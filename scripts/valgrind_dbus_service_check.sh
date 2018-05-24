#!/usr/bin/env bash

set -e
make -j4

DIRECTORY=`dirname $0`

if [ ! -d ${DIRECTORY}/tmp/GNOME.supp ]; then
    mkdir -p ${DIRECTORY}/tmp;
    (cd ${DIRECTORY}/tmp; git clone https://github.com/dtrebbien/GNOME.supp.git);
fi

(cd ${DIRECTORY}/tmp/GNOME.supp; make)

[ `whoami` = root ] || exec sudo su -c $0 root

echo 'make install; remove dbus service'
make install

[ -d /usr/share/dbus-1 ] && find /usr/share/dbus* -name "ddccontrol.DDCControl.service" -exec rm '{}' \;
[ -d /usr/local/share/dbus-1 ] && find /usr/local/share/dbus* -name "ddccontrol.DDCControl.service" -exec rm '{}' \;

VALGRIND_OUT=$(mktemp /tmp/ddccontrol_service.valgrind.out.XXXXXXXX)
chmod 755 "${VALGRIND_OUT}"

echo "kill all ddccontrol & ddcpci processes"
pkill ddccontrol || true
pkill ddcpci || true

sleep 0.25

pgrep ddc || true

CCMD="libtool --mode=execute valgrind --suppressions='$(pwd)'/scripts/tmp/GNOME.supp/build/{base,gio,glib}.supp --leak-check=full --log-file='${VALGRIND_OUT}' '$(pwd)/src/daemon/ddccontrol_service'"
echo "starting service: $CCMD"
su -c "$CCMD" &
DDCCONTROL_DBUS_SERVICE_PID=$!

sleep 5

echo "run tests"
"$(pwd)/src/ddccontrol/ddccontrol" -p >/dev/null

kill -15 ${DDCCONTROL_DBUS_SERVICE_PID}

echo "valgrind output written to: ${VALGRIND_OUT}"
