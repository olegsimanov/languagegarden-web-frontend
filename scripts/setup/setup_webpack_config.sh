#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$SCRIPT_DIR/set_vars.sh"

set -e
set -u


WEBPACK_CFG_FILEPATH="$COMPONENTS_DIR/webpack-instance-config.js"

echo ">>> Creating $WEBPACK_CFG_FILEPATH"
"$EXTRACT_CMD" "$INSTANCE_TYPE" webpack-config-file > "$WEBPACK_CFG_FILEPATH"
