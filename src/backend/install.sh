install() {
    printlog true "Installing  $ADDON_TITLE..." $CINFO

    opkg install jq
    opkg install curl
    opkg install sed
    opkg install flock
    opkg install bash

    mkdir -p "$DIR_WEB" || {
        printlog true "Failed to create directory $DIR_WEB" $CERR
    }

    # Add or update post-mount
    printlog true "Ensuring /jffs/scripts/post-mount contains required entry."
    mkdir -p /jffs/scripts
    if [ ! -f /jffs/scripts/post-mount ]; then
        echo "#!/bin/sh" >/jffs/scripts/post-mount
    else
        printlog true "Removing existing #$ADDON_TAG entries from /jffs/scripts/post-mount."
        sed -i /#$ADDON_TAG/d /jffs/scripts/post-mount
    fi
    chmod +x /jffs/scripts/post-mount
    echo "/jffs/scripts/$ADDON_TAG remount_ui"' "$@" & #'"$ADDON_TAG" >>/jffs/scripts/post-mount
    printlog true "Updated /jffs/scripts/post-mount with $ADDON_TAG entry." $CSUC

    # Add or update service-event
    printlog true "Ensuring /jffs/scripts/service-event contains required entry."
    if [ ! -f /jffs/scripts/service-event ]; then
        echo "#!/bin/sh" >/jffs/scripts/service-event
    else
        printlog true "Removing existing #$ADDON_TAG entries from /jffs/scripts/service-event."
        sed -i /#$ADDON_TAG/d /jffs/scripts/service-event
    fi
    chmod +x /jffs/scripts/service-event
    echo "echo \"\$2\" | grep -q \"^$ADDON_TAG\" && /jffs/scripts/$ADDON_TAG service_event \$(echo \"\$2\" | cut -d'_' -f2- | tr '_' ' ') & #$ADDON_TAG" >>/jffs/scripts/service-event
    printlog true "Updated /jffs/scripts/service-event with $ADDON_TITLE entry." $CSUC

    remount_ui

    download_zapret || printlog true "Failed to download zapret" $CERR

    extract_and_install_zapret || printlog true "Failed to extract and install zapret" $CERR

    printlog true
    printlog true "=============================" $CSUC
    printlog true "Installing $ADDON_TITLE... done" $CSUC
    printlog true "=============================" $CSUC
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

download_zapret() {
    local LATEST_API_URL="https://api.github.com/repos/bol-van/zapret/releases/latest"
    printlog true "Fetching latest release info from GitHub..." $CINFO

    # Fetch release info from GitHub
    local JSON=$(curl -s "$LATEST_API_URL")
    # Use jq to extract the first asset that ends with "tar.gz"
    ZAPRET_DOWNLOAD_URL=$(echo "$JSON" | jq -r '.assets[] | select(.name | (contains("openwrt") and endswith("openwrt-embedded.tar.gz"))) | .browser_download_url')

    if [ -z "$ZAPRET_DOWNLOAD_URL" ]; then
        printlog true "Could not determine the download URL from GitHub API" $CERR
        return 1
    fi

    local DEST_FILE="/tmp/$(basename "$ZAPRET_DOWNLOAD_URL")"
    printlog true "Downloading latest version from $ZAPRET_DOWNLOAD_URL..." $CINFO

    curl -L -o "$DEST_FILE" "$ZAPRET_DOWNLOAD_URL" || {
        printlog true "Failed to download file from $ZAPRET_DOWNLOAD_URL" $CERR
        return 1
    }
    printlog true "Downloaded latest version to $DEST_FILE" $CSUC
}

extract_and_install_zapret() {
    # Assuming the tarball was downloaded to /tmp and its name is derived from the URL.
    local TARBALL="/tmp/$(basename "$ZAPRET_DOWNLOAD_URL")"

    rm -rf "$ZAPRET_DIR"

    # Ensure the target extraction directory exists
    mkdir -p "$ZAPRET_DIR" || {
        printlog true "Failed to create extraction directory $ZAPRET_DIR" $CERR
        return 1
    }

    local TEMP_DIR="/tmp/zapret-extract"
    mkdir -p "$TEMP_DIR" || {
        printlog true "Failed to create temporary directory $TEMP_DIR" $CERR
        return 1
    }

    printlog true "Extracting $TARBALL to temporary directory $TEMP_DIR..." $CINFO
    tar -xzvf "$TARBALL" -C "$TEMP_DIR" || {
        printlog true "Failed to extract $TARBALL" $CERR
        return 1
    }

    local SINGLE_DIR
    SINGLE_DIR=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)

    if [ -n "$SINGLE_DIR" ]; then
        printlog true "Moving contents of $SINGLE_DIR to $ZAPRET_DIR..." $CINFO
        mv "$SINGLE_DIR"/* "$ZAPRET_DIR"/ || {
            printlog true "Failed to move files from $SINGLE_DIR to $ZAPRET_DIR" $CERR
            return 1
        }
    else
        printlog true "Moving files from $TEMP_DIR to $ZAPRET_DIR..." $CINFO
        mv "$TEMP_DIR"/* "$ZAPRET_DIR"/ || {
            printlog true "Failed to move files from $TEMP_DIR to $ZAPRET_DIR" $CERR
            return 1
        }
    fi

    rm -rf "$TEMP_DIR"

    local INSTALL_BIN_SCRIPT
    INSTALL_BIN_SCRIPT=$(find "$ZAPRET_DIR" -type f -name 'install_bin.sh' | head -n 1)
    local INSTALL_PREREQ_SCRIPT
    INSTALL_PREREQ_SCRIPT=$(find "$ZAPRET_DIR" -type f -name 'install_prereq.sh' | head -n 1)

    printlog true "Running install script: $INSTALL_BIN_SCRIPT" $CINFO
    sh "$INSTALL_BIN_SCRIPT" || {
        printlog true "Failed to run install_bin.sh" $CERR
        return 1
    }

    printlog true "zapret installed successfully" $CSUC
}
