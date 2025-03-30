install() {
    printlog true "Uninstalling $ADDON_TITLE..." $CINFO

    opkg install jq
    opkg install curl
    opkg install sed
    opkg install flock

    mkdir -p "$DIR_WEB" || {
        printlog true "Failed to create directory $DIR_WEB" $CERR
    }

    remount_ui

    printlog true "Uninstalling $ADDON_TITLE... done" $CSUC
}

uninstall() {
    printlog true "Uninstalling $ADDON_TITLE..." $CINFO

    printlog true "Unmounting $ADDON_TITLE..." $CINFO
    unmount_ui

    rm -rf /www/user/$ADDON_TAG /jffs/addons/$ADDON_TAG /tmp/$ADDON_TAG*.json

    # clean up services-start
    printlog true "Removing existing #$ADDON_TAG entries from /jffs/scripts/services-start."
    sed -i /#$ADDON_TAG/d /jffs/scripts/services-start

    # clean up nat-start
    printlog true "Removing existing #$ADDON_TAG entries from /jffs/scripts/nat-start."
    sed -i /#$ADDON_TAG/d /jffs/scripts/nat-start

    # clean up post-mount
    printlog true "Removing existing #$ADDON_TAG entries from /jffs/scripts/post-mount."
    sed -i /#$ADDON_TAG/d /jffs/scripts/post-mount

    # clean up service-event
    printlog true "Removing existing #$ADDON_TAG entries from /jffs/scripts/service-event."
    sed -i /#$ADDON_TAG/d /jffs/scripts/service-event

    # clean up firewall-start
    printlog true "Removing existing #$ADDON_TAG entries from /jffs/scripts/firewall-start."
    sed -i /#$ADDON_TAG/d /jffs/scripts/firewall-start

    rm -f /jffs/scripts/$ADDON_TAG

    printlog true "Uninstalling $ADDON_TITLE... done" $CSUC
}
