#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$SCRIPT_DIR/set_vars.sh"

set -e
set -u


if [ ! -d "${VIRTUAL_ENV}" ]
then
    echo "ERROR: please activate virtualenv."
    exit 1
fi

SETTINGS_FILENAME=`"$EXTRACT_CMD" "$INSTANCE_TYPE" settings-filename`
SETTINGS_FILEPATH="$BACKEND_DIR/languagegarden/settings/$SETTINGS_FILENAME"
MANAGE_FILEPATH="$BACKEND_DIR/manage.py"

echo ">>> Creating $MANAGE_FILEPATH"
"$EXTRACT_CMD" "$INSTANCE_TYPE" manage-file > "$MANAGE_FILEPATH"
chmod +x "$MANAGE_FILEPATH"

echo ">>> Creating $SETTINGS_FILEPATH"
"$EXTRACT_CMD" "$INSTANCE_TYPE" settings-file > "$SETTINGS_FILEPATH"
