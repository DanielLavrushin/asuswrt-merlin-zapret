TPWS_BIN="$ZAPRET_DIR/tpws/tpws"
NFQWS_BIN="$ZAPRET_DIR/nfq/nfqws"

TPWS_PID="/var/run/zapret_tpws.pid"
NFQWS_PID="/var/run/zapret_nfqws.pid"

ZAPRET_TPWS_INTERFACE="${ZAPRET_TPWS_INTERFACE:-$(nvram get wan0_ifname)}"
ZAPRET_TPWS_PORT="${ZAPRET_TPWS_PORT:-10180}"

QNUM=200
WS_USER="$(nvram get http_username)"
DESYNC_MARK=0x40000000

start_zapret() {

    printlog true "Starting Zapret daemons..." $CINFO

    start_firewall

    if [ -x "$TPWS_BIN" ]; then
        printlog true "Starting tpws on port $ZAPRET_TPWS_PORT..." $CINFO

        "$TPWS_BIN" --daemon --pidfile="$TPWS_PID" --port="$ZAPRET_TPWS_PORT" &
        sleep 1
    else
        printlog true "tpws binary not found at $TPWS_BIN (skipping)" $CERR
    fi

    if [ -x "$NFQWS_BIN" ]; then
        printlog true "Starting nfqws..." $CINFO
        "$NFQWS_BIN" --daemon --pidfile="$NFQWS_PID" --user="$WS_USER" --dpi-desync-fwmark="$DESYNC_MARK" --qnum="$QNUM" &
        sleep 1
    else
        printlog true "nfqws binary not found at $NFQWS_BIN (skipping)" $CERR
    fi

    printlog true "Starting Zapret daemons... done" $CSUC
}

stop_zapret() {
    printlog true "Stopping Zapret daemons..." $CINFO

    printlog true "Stopping tpws..." $CINFO
    pkill -9 -f "$TPWS_BIN"
    rm -f "$TPWS_PID"

    printlog true "Stopping nfqws..." $CINFO
    pkill -9 -f "$NFQWS_BIN"
    rm -f "$NFQWS_PID"

    stop_firewall

    printlog true "Stopping Zapret daemons... done" $CSUC
}

status_zapret() {
    # Check tpws:
    if [ -f "$TPWS_PID" ]; then
        TPWS_PID_VAL=$(cat "$TPWS_PID")
        if kill -0 "$TPWS_PID_VAL" 2>/dev/null; then
            printlog true "tpws is running (PID $TPWS_PID_VAL)." $CSUC

        else
            if netstat -an | grep -q ":$ZAPRET_TPWS_PORT"; then
                printlog true "tpws appears to be running (port $ZAPRET_TPWS_PORT is in use)." $CINFO
            else
                printlog true "tpws PID file exists but process is not running." $CERR
            fi
        fi
    else
        if netstat -an | grep -q ":$ZAPRET_TPWS_PORT"; then
            printlog true "tpws appears to be running (port $ZAPRET_TPWS_PORT is in use)." $CINFO
        else
            printlog true "tpws is not running." $CWARN
        fi
    fi

    # Check nfqws:
    if [ -f "$NFQWS_PID" ]; then
        NFQWS_PID_VAL=$(cat "$NFQWS_PID")
        if kill -0 "$NFQWS_PID_VAL" 2>/dev/null; then
            printlog true "nfqws is running (PID $NFQWS_PID_VAL)." $CSUC
        else
            printlog true "nfqws PID file exists but process is not running." $CERR
        fi
    else
        printlog true "nfqws is not running." $CWARN
    fi
}

restart_zapret() {
    printlog true "Restarting Zapret daemons..." $CINFO
    stop_zapret
    sleep 1
    start_zapret

    printlog true "Restarting Zapret daemons... done" $CSUC
}
