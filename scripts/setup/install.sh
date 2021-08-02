#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$SCRIPT_DIR/set_vars.sh"

set -euo pipefail


$SCRIPT_DIR/setup_venv.sh                             # installs nodeenv
$SCRIPT_DIR/update_system_requirements.sh             # installs brew packages
#$SCRIPT_DIR/setup_settings.sh                        # for backend only
$SCRIPT_DIR/setup_webpack_config.sh                   # ../../deployment/salt/webpack/config.js => ../../components/webpack-instance-config.js
$SCRIPT_DIR/update_requirements.sh
