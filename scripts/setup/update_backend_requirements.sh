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

echo '>>> Installing PIP requirements'

"$EXTRACT_CMD" "$INSTANCE_TYPE" pip-requirements > autogen_requirements.txt
pip install -r autogen_requirements.txt
rm autogen_requirements.txt
