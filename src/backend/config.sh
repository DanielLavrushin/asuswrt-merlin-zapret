init_config() {
    if [ -f "$ZAPRETUI_CONFIG" ]; then
        . "$ZAPRETUI_CONFIG"
    fi
}

update_config() {
    local key="$1"
    local value="$2"
    [ -f "$ZAPRETUI_CONFIG" ] || touch "$ZAPRETUI_CONFIG"
    if grep -qE "^${key}=" "$ZAPRETUI_CONFIG"; then
        sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$ZAPRETUI_CONFIG"
    else
        echo "${key}=\"${value}\"" >>"$ZAPRETUI_CONFIG"
    fi
}
