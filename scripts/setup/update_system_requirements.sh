#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$SCRIPT_DIR/set_vars.sh"

set -euo pipefail


if [ "$(uname -s)" = "Darwin" ]; then
    if ! command -v brew > /dev/null; then
        echo "ERROR: brew (https://brew.sh/) is not installed"
        exit 1
    fi

    "$EXTRACT_CMD" "$INSTANCE_TYPE" brewfile-requirements > autogen-brewfile.txt

    echo '>>> Installing Mac OS requirements'
    brew bundle install --file=autogen-brewfile.txt
    rm autogen-brewfile.txt
else
    "$EXTRACT_CMD" "$INSTANCE_TYPE" debian-requirements > autogen-debian-requirements.txt

    echo '>>> Installing Debian/Ubuntu requirements'
    "$XARGS_CMD" -a autogen-debian-requirements.txt sudo apt-get install
    rm autogen-debian-requirements.txt
fi
