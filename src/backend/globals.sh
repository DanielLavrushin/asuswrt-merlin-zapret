export PATH=/opt/bin:/opt/sbin:/sbin:/bin:/usr/sbin:/usr/bin

source /usr/sbin/helper.sh

VERSION="1.0.0"
ADDON_TAG="zapretui"
ADDON_TAG_UPPER="ZAPRETUI"
ADDON_NAME="Zapret UI"
ADDON_TITLE="Zapret UI"

ZAPRET_DIR="/opt/etc/zapret"
ZAPRET_BIN_DIR="$ZAPRET_DIR/bin"
ZAPRET_BIN="$ZAPRET_BIN_DIR/zapret"

LOCKFILE=/tmp/$ADDON_TAG.lock

DIR_WEB="/www/user/$ADDON_TAG"
DIR_SHARE="/opt/share/$ADDON_TAG"
DIR_JFFS_ADDONS="/jffs/addons/$ADDON_TAG"

UI_RESPONSE_FILE="/tmp/${ADDON_TAG}_response.json"

CERR='\033[0;31m'
CSUC='\033[0;32m'
CWARN='\033[0;33m'
CINFO='\033[0;36m'
CRESET='\033[0m'
