start_firewall() {
    printlog true "Setting up iptables redirection rules..." $CINFO
    iptables -t nat -I OUTPUT -o "$ZAPRET_TPWS_INTERFACE" -p tcp --dport 80 -j DNAT --to-destination 127.0.0.1:"$ZAPRET_TPWS_PORT"
    iptables -t nat -I OUTPUT -o "$ZAPRET_TPWS_INTERFACE" -p tcp --dport 443 -j DNAT --to-destination 127.0.0.1:"$ZAPRET_TPWS_PORT"
}

stop_firewall() {
    printlog true "Removing iptables redirection rules..." $CINFO
    iptables -t nat -D OUTPUT -o "$ZAPRET_TPWS_INTERFACE" -p tcp --dport 80 -j DNAT --to-destination 127.0.0.1:"$ZAPRET_TPWS_PORT" 2>/dev/null
    iptables -t nat -D OUTPUT -o "$ZAPRET_TPWS_INTERFACE" -p tcp --dport 443 -j DNAT --to-destination 127.0.0.1:"$ZAPRET_TPWS_PORT" 2>/dev/null
}
