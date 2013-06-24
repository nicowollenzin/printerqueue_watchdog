#!/bin/bash
#
#  Copyright (C) 2011-2012, Nico Wollenzin <nico@wollenzin.de>
#
#  printerqueue Watchdog is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by
#  the Free Software Foundation; version 2.
#
#  This package is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

### BEGIN INIT INFO
# Provides: pq_watchdog
# Required-Start: $local_fs $network
# Required-Stop: $local_fs $network
# Default-Start:  2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: FHEM printer queue watchdog daemon
# Description: turns on and off aour printer when jobs are queued
### END INIT INFO


set -e
set -u

i=0

if [ -f /etc/default/pq_watchdog ]; then
        . /etc/default/pq_watchdog
else
        echo "Missing required file /etc/default/pq_watchdog."
        exit 1
fi

if [ $# -lt 1 ]
then
        echo "$0 <start|stop|restart|status>"
        exit 1
fi

. /lib/lsb/init-functions

function mklogfile() {
        if [ ! -z "$1" -a ! -e "$1" ]; then
                touch "$1"
        fi
}

case $1 in
        start)
                log_daemon_msg "Starting" "PQ watchdog systemd"
                mklogfile "$PQWD_LOGFILE"
                env - PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
                        start-stop-daemon --pidfile=$PQWD_PIDFILE --make-pidfile --background --oknodo --start \
                        --exec $BASH -- $PQWD
                while ! start-stop-daemon --pidfile=$PQWD_PIDFILE --test --stop --exec $BASH --quiet; do
                        sleep .1
                        if [ $i -ge 100 ]; then
                                log_failure_msg "PQ watchdog start failed"
                                log_end_msg 1
                                exit 1
                        else
                                i=$(( i + 1 ))
                        fi
                done
                log_end_msg 0
                ;;
        
        stop)
                log_daemon_msg "Stopping" "PQ watchdog systemd"
                env - PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
                        start-stop-daemon --pidfile=$PQWD_PIDFILE --stop --oknodo --exec $BASH
                while start-stop-daemon --pidfile=$PQWD_PIDFILE --test --stop --exec $BASH --quiet; do
                        sleep .1
                        if [ $i -ge 100 ]; then
                                log_failure_msg "PQ watchdog stop failed"
                                log_end_msg 1
                                exit 1
                        else
                                i=$(( i + 1 ))
                        fi
                done
                log_end_msg 0
                ;;
        
        restart|reload|force-reload)
                $0 stop
                $0 start
                ;;
        
        status)
                if start-stop-daemon --pidfile=$PQWD_PIDFILE --test --stop --exec $BASH --quiet
                then
                        PID=`cat $PQWD_PIDFILE`
                        echo "watchdog is running (pid $PID)."
                        exit 0
                else
                        echo "watchdog is not running"
                        exit 3
                fi
                ;;
        
        probe)
                echo restart
                exit 0
                ;;
        
        *)
                echo "Unknown command $1."
                exit 1
                ;;
esac