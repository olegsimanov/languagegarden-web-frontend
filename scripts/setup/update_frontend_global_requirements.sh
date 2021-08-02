#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$SCRIPT_DIR/set_vars.sh"

set -euo pipefail


if [ -z "$NPM_PATH" ]
then
    echo "ERROR: no npm detected."
    exit 1
fi

echo '>>> Installing NPM global requirements'
"$XARGS_CMD" -a autogen-npm-global-requirements.txt npm install -g
