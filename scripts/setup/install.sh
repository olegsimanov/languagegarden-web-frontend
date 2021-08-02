#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$SCRIPT_DIR/set_vars.sh"

set -euo pipefail


$SCRIPT_DIR/setup_venv.sh
$SCRIPT_DIR/update_system_requirements.sh
$SCRIPT_DIR/setup_settings.sh
$SCRIPT_DIR/setup_webpack_config.sh
$SCRIPT_DIR/update_requirements.sh
