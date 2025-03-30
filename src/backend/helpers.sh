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

update_loading_progress() {
    local message=$1
    local progress=$2

    load_ui_response

    if [ -n "$progress" ]; then

        UI_RESPONSE=$(echo "$UI_RESPONSE" | jq --argjson progress "$progress" --arg message "$message" '
            .loading.message = $message |
            .loading.progress = $progress
        ')
    else
        UI_RESPONSE=$(echo "$UI_RESPONSE" | jq --arg message "$message" '
            .loading.message = $message
        ')
    fi

    echo "$UI_RESPONSE" >"$XRAY_UI_RESPONSE_FILE"

    if [ "$progress" = "100" ]; then
        /jffs/scripts/zapretui service_event cleanloadingprogress &
    fi

}

remove_loading_progress() {
    printlog true "Removing loading progress..."
    sleep 1
    load_ui_response

    local UI_RESPONSE=$(cat "$XRAY_UI_RESPONSE_FILE")

    UI_RESPONSE=$(echo "$UI_RESPONSE" | jq '
            del(.loading)
        ')

    echo "$UI_RESPONSE" >"$XRAY_UI_RESPONSE_FILE"
    exit 0
}

cleanup_payloads() {
    sed -i '/^zapretui_payload/d' /jffs/addons/custom_settings.txt
}

load_ui_response() {

    if [ ! -f "$UI_RESPONSE_FILE" ]; then
        printlog true "Creating $ADDON_TITLE response file: $UI_RESPONSE_FILE"
        echo '{}' >"$UI_RESPONSE_FILE"
        chmod 600 "$UI_RESPONSE_FILE"
    fi

    if [ -f "$UI_RESPONSE_FILE" ]; then
        UI_RESPONSE=$(cat "$UI_RESPONSE_FILE")
    else
        UI_RESPONSE="{}"
    fi

}

save_ui_response() {
    echo "$UI_RESPONSE" >"$UI_RESPONSE_FILE" || {
        printlog true "Failed to save UI response to $UI_RESPONSE_FILE" $CERR
        return 1
    }
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
        chunk=$(am_settings_get zapretui_payload$idx)
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
