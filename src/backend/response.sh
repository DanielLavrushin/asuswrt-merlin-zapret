initial_response() {
    init_config
    load_ui_response

    ZAPRET_TPWS_PORT="${ZAPRET_TPWS_PORT:-$ZAPRET_TPWS_PORT}"
    ZAPRET_TPWS_INTERFACE="${ZAPRET_TPWS_INTERFACE:-$ZAPRET_TPWS_INTERFACE}"

    ZAPRET_NFQWS_QNUM="${ZAPRET_NFQWS_QNUM:-200}"
    ZAPRET_NFQWS_DESYNC_MASK="${ZAPRET_NFQWS_DESYNC_MASK:-0x40000000}"

    UI_RESPONSE=$(echo "$UI_RESPONSE" | jq --argjson val "$ZAPRET_TPWS_PORT" '.tpws.port = $val')
    UI_RESPONSE=$(echo "$UI_RESPONSE" | jq --arg val "$ZAPRET_TPWS_INTERFACE" '.tpws.interface = $val')

    UI_RESPONSE=$(echo "$UI_RESPONSE" | jq --argjson val "$ZAPRET_NFQWS_QNUM" '.nfqws.qnum = $val')
    UI_RESPONSE=$(echo "$UI_RESPONSE" | jq --arg val "$ZAPRET_NFQWS_DESYNC_MASK" '.nfqws.desync_mark = $val')

    local interfaces="$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(eth|wl|br|wan)' | tr '\n' ',' | sed 's/,$//')"
    UI_RESPONSE=$(echo "$UI_RESPONSE" | jq --arg ifaces "$interfaces" '.tpws.interfaces = ($ifaces | split(","))') || {
        printlog true "Failed to set tpws interfaces in UI response." $CERR
        exit 1
    }

    save_ui_response

    if [ $? -ne 0 ]; then
        printlog true "Failed to save UI response." $CERR
        exit 1
    fi

    printlog true "UI response saved to $UI_RESPONSE_FILE" $CSUC
}

apply_response() {
    printlog true "Applying zapret settings..." $CINFO
    update_loading_progress "Applying zapret settings..." 0

    init_config
    load_ui_response

    local genopts=$(reconstruct_payload)

    local ZAPRET_TPWS_PORT=$(echo "$genopts" | jq -r '.tpws.port')
    local ZAPRET_TPWS_INTERFACE=$(echo "$genopts" | jq -r '.tpws.interface')

    local ZAPRET_NFQWS_QNUM=$(echo "$genopts" | jq -r '.nfqws.qnum')
    local ZAPRET_NFQWS_DESYNC_MASK=$(echo "$genopts" | jq -r '.nfqws.desync_mark')

    update_config "ZAPRET_TPWS_PORT" "$ZAPRET_TPWS_PORT"
    update_config "ZAPRET_TPWS_INTERFACE" "$ZAPRET_TPWS_INTERFACE"

    update_config "ZAPRET_NFQWS_QNUM" "$ZAPRET_NFQWS_QNUM"
    update_config "ZAPRET_NFQWS_DESYNC_MASK" "$ZAPRET_NFQWS_DESYNC_MASK"

    save_ui_response

    if [ $? -ne 0 ]; then
        printlog true "Failed to save UI response." $CERR
        exit 1
    fi

    printlog true "UI response saved to $UI_RESPONSE_FILE" $CSUC

    update_loading_progress "Restarting Zapret daemons..."
    restart_zapret

    printlog true "Zapret settings applied." $CSUC
    update_loading_progress "Zapret settings applied." 100

}
