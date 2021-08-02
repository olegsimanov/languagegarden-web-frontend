#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$SCRIPT_DIR/set_vars.sh"

set -e
set -u


$SCRIPT_DIR/update_backend_requirements.sh
$SCRIPT_DIR/update_frontend_requirements.sh
