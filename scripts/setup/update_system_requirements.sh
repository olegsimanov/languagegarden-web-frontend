#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$SCRIPT_DIR/set_vars.sh"

set -euo pipefail


if ! command -v brew > /dev/null; then
    echo "ERROR: brew (https://brew.sh/) is not installed"
    exit 1
fi

#"$EXTRACT_CMD" "$INSTANCE_TYPE" brewfile-requirements > autogen-brewfile.txt

echo '>>> Installing Mac OS requirements'
brew bundle install --file=autogen-brewfile.txt
#rm autogen-brewfile.txt
rm autogen-brewfile.txt.lock.json
