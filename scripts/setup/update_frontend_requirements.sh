#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$SCRIPT_DIR/set_vars.sh"

set -e
set -u


echo '>>> Installing NPM global requirements'
"$XARGS_CMD" -a autogen-npm-global-requirements.txt npm install -g

cd "$COMPONENTS_DIR"
if [ ! -f "package.json" ]
then
    echo "ERROR: please execute this script from frontend/components directory."
    exit 1
fi

echo '>>> Installing NPM local requirements'
npm install

echo '>>> Installing Bower dependencies'
bower install

