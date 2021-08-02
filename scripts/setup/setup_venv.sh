#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$SCRIPT_DIR/set_vars.sh"

set -euo pipefail


if [ ! -d "${VIRTUAL_ENV}" ]
then
    echo "ERROR: please activate virtualenv."
    exit 1
fi

if [ "$(python -c 'from __future__ import print_function;import sys;print(sys.version_info.major)')" != "2" ]
then
    echo "ERROR: Python 2 is required."
    exit 1
fi

# preinstalling PyYAML/jinja2 (required for extract_deployment_data.py)
pip install PyYAML jinja2

if [ "$NPM_PATH" == "${VIRTUAL_ENV}/bin/npm" ]
then
    echo "NPM detected, nothing to do here"
    exit 0
fi

pip install nodeenv
nodeenv -pv -n 6.11.0
