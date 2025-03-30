#!/bin/sh

import ./globals.sh
import ./helpers.sh
import ./install.sh
import ./start.sh
import ./mountui.sh

case "$1" in
install)
    install
    ;;
uninstall)
    uninstall
    ;;
start)
    start
    ;;
stop)
    stop
    ;;
restart)
    restart
    ;;
startup)
    startup
    ;;
update)
    update
    ;;
mount_ui)
    mount_ui
    ;;
unmount_ui)
    unmount_ui
    ;;
remount_ui)
    remount_ui $2
    ;;
service_event)
    case "$2" in
    update)
        update
        ;;
    service)
        case "$3" in
        start)
            start
            ;;
        stop)
            stop
            ;;
        esac
        ;;
    cleanloadingprogress)
        remove_loading_progress
        ;;
    esac
    exit 0
    ;;
*)
    echo "Usage: $0 {install|uninstall|start|stop|restart|update|mount_ui|unmount_ui|remount_ui}"
    exit 1
    ;;
esac

exit 0
