printlog() {
    if [ "$1" = "true" ]; then
        logger -t "$ADDON_TAG_UPPER" "$2"
    fi
    printf "${CINFO}${3}%s${CRESET}\\n" "$2"
}

get_webui_page() {
    ADDON_USER_PAGE="none"
    local max_user_page=0
    local used_pages=""

    for page in /www/user/user*.asp; do
        if [ -f "$page" ]; then
            if grep -q "page:$ADDON_TAG" "$page"; then
                ADDON_USER_PAGE=$(basename "$page")
                printlog true "Found existing $ADDON_TAG_UPPER page: $ADDON_USER_PAGE" $CSUC
                return
            fi

            user_number=$(echo "$page" | sed -E 's/.*user([0-9]+)\.asp$/\1/')
            used_pages="$used_pages $user_number"

            if [ "$user_number" -gt "$max_user_page" ]; then
                max_user_page="$user_number"
            fi
        fi
    done

    if [ "$ADDON_USER_PAGE" != "none" ]; then
        printlog true "Found existing $ADDON_TAG_UPPER page: $ADDON_USER_PAGE" $CSUC
        return
    fi

    if [ "$1" = "true" ]; then
        i=1
        while true; do
            if ! echo "$used_pages" | grep -qw "$i"; then
                ADDON_USER_PAGE="user$i.asp"
                printlog true "Assigning new $ADDON_TAG_UPPER page: $ADDON_USER_PAGE" $CSUC
                return
            fi
            i=$((i + 1))
        done
    fi
}

remove_loading_progress() {
    printlog true "Removing loading progress..."
    sleep 1
    ensure_ui_response_file

    UI_RESPONSE=$(echo "$UI_RESPONSE" | jq '
            del(.loading)
        ')

    echo "$UI_RESPONSE" >"$UI_RESPONSE_FILE"
    exit 0
}

cleanup_payloads() {
    sed -i '/^yuui_payload/d' /jffs/addons/custom_settings.txt
}

ensure_ui_response_file() {
    if [ ! -f "$UI_RESPONSE_FILE" ]; then
        printlog true "Creating $ADDON_TITLE response file: $UI_RESPONSE_FILE"
        echo '{"yuui":{}}' >"$UI_RESPONSE_FILE"
        chmod 600 "$UI_RESPONSE_FILE"
    fi

    if [ -f "$UI_RESPONSE_FILE" ]; then
        UI_RESPONSE=$(cat "$UI_RESPONSE_FILE")
    else
        UI_RESPONSE="{}"
    fi

}

am_settings_del() {
    local key="$1"
    sed -i "/$key/d" /jffs/addons/custom_settings.txt
}

reconstruct_payload() {
    FD=386
    eval exec "$FD>$LOCKFILE"

    if ! flock -x "$FD"; then
        return 1
    fi

    local idx=0
    local chunk
    local payload=""
    while :; do
        chunk=$(am_settings_get yuui_payload$idx)
        if [ -z "$chunk" ]; then
            break
        fi
        payload="$payload$chunk"
        idx=$((idx + 1))
    done

    cleanup_payloads

    echo "$payload"

    flock -u "$FD"
}
