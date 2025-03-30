mount_ui() {

    FD=386
    eval exec "$FD>$LOCKFILE"
    flock -x "$FD"

    nvram get rc_support | grep -q am_addons
    if [ $? != 0 ]; then
        printlog true "This firmware does not support addons!" $CERR
        exit 5
    fi

    get_webui_page true

    if [ "$ADDON_USER_PAGE" = "none" ]; then
        printlog true "Unable to install $ADDON_TAG_UPPER" $CERR
        exit 5
    fi

    printlog true "Mounting $ADDON_TAG_UPPER as $ADDON_USER_PAGE"

    if [ ! -d $DIR_WEB ]; then
        mkdir -p "$DIR_WEB"
    fi

    if [ ! -d "$DIR_SHARE/data" ]; then
        mkdir -p "$DIR_SHARE/data"
    fi
    ensure_ui_response_file

    ln -s -f /jffs/addons/$ADDON_TAG/index.asp /www/user/$ADDON_USER_PAGE
    ln -s -f /jffs/addons/$ADDON_TAG/app.js $DIR_WEB/app.js
    ln -s -f $UI_RESPONSE_FILE $DIR_WEB/response.json
    ln -s -f /jffs/addons/$ADDON_TAG/assets/ $DIR_WEB/assets

    echo "$ADDON_TAG_UPPER" >"/www/user/$(echo $ADDON_USER_PAGE | cut -f1 -d'.').title"

    if [ ! -f /tmp/menuTree.js ]; then
        cp /www/require/modules/menuTree.js /tmp/
        mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
    fi

    sed -i '/index: "menu_VPN"/,/index:/ {
  /url:\s*"NULL",\s*tabName:\s*"__INHERIT__"/ i \
    { url: "'"$ADDON_USER_PAGE"'", tabName: "'"$ADDON_TITLE"'" },
}' /tmp/menuTree.js

    umount /www/require/modules/menuTree.js && mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js

    flock -u "$FD"
    printlog true "$ADDON_TAG_UPPER mounted successfully as $ADDON_USER_PAGE" $CSUC
}

unmount_ui() {
    FD=386
    eval exec "$FD>$LOCKFILE"
    flock -x "$FD"

    nvram get rc_support | grep -q am_addons
    if [ $? != 0 ]; then
        printlog true "This firmware does not support addons!" $CERR
        exit 5
    fi

    get_webui_page

    base_user_page="${ADDON_USER_PAGE%.asp}"

    if [ -z "$ADDON_USER_PAGE" ] || [ "$ADDON_USER_PAGE" = "none" ]; then
        printlog true "No $ADDON_TAG_UPPER page found to unmount. Continuing to clean up..." $CWARN
    else
        printlog true "Unmounting $ADDON_TAG_UPPER $ADDON_USER_PAGE"
        rm -fr /www/user/$ADDON_USER_PAGE
        rm -fr /www/user/$base_user_page.title
    fi

    if [ ! -f /tmp/menuTree.js ]; then
        printlog true "menuTree.js not found, skipping unmount." $CWARN
    else
        printlog true "Removing any $ADDON_TITLE menu entry from menuTree.js."

        grep -v "tabName: \"$ADDON_TITLE\"" /tmp/menuTree.js >/tmp/menuTree_temp.js
        mv /tmp/menuTree_temp.js /tmp/menuTree.js

        umount /www/require/modules/menuTree.js
        mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
    fi

    rm -rf $DIR_WEB

    flock -u "$FD"

    printlog true "Unmount completed." $CSUC
}

remount_ui() {
    LOCKFILE=/tmp/addonwebui.lock
    FD=386
    eval exec "$FD>$LOCKFILE"
    flock -x "$FD"

    unmount_ui
    mount_ui

    flock -u "$FD"
}
