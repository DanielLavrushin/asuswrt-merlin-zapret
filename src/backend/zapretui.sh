#!/bin/sh

import ./globals.sh
import ./helpers.sh

import ./config.sh
import ./install.sh
import ./start.sh
import ./mountui.sh
import ./firewall.sh
import ./zapret.sh
import ./response.sh

# Main command parser
case "$1" in
install)
    install
    ;;
uninstall)
    uninstall
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
    remount_ui "$2"
    ;;
zapret)
    case "$2" in
    start)
        start_zapret
        ;;
    stop)
        stop_zapret
        ;;
    status)
        status_zapret
        ;;
    restart)
        restart_zapret
        ;;
    *)
        echo "Usage: $0 zapret {start|stop|status|restart}"
        exit 1
        ;;
    esac
    ;;
service_event)
    case "$2" in
    web)
        case "$3" in
        start)
            update_loading_progress "Starting Zapret daemons..."
            start_zapret
            update_loading_progress "Starting Zapret daemons..." 100
            ;;
        stop)
            update_loading_progress "Stopping Zapret daemons..."
            stop_zapret
            update_loading_progress "Stopping Zapret daemons..." 100
            ;;
        restart)
            update_loading_progress "Restarting Zapret daemons..."
            restart_zapret
            update_loading_progress "Restarting Zapret daemons..." 100
            ;;
        apply)
            apply_response
            ;;
        initresponse)
            initial_response
            ;;
        *)
            echo "Usage: $0 service_event web {start|stop|initresponse}"
            exit 1
            ;;
        esac
        ;;
    service)
        case "$3" in
        start)
            start
            ;;
        stop)
            stop
            ;;
        *)
            echo "Usage: $0 service_event service {start|stop}"
            exit 1
            ;;
        esac
        ;;
    cleanloadingprogress)
        remove_loading_progress
        ;;
    *)
        echo "Usage: $0 service_event {update|service [start|stop]|cleanloadingprogress}"
        exit 1
        ;;
    esac
    exit 0
    ;;
*)
    echo "Usage: $0 {install|uninstall|start|stop|restart|update|mount_ui|unmount_ui|remount_ui|zapret [start|stop|status|restart]|service_event ...}"
    exit 1
    ;;
esac

exit 0
