#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$SCRIPT_DIR/set_vars.sh"

set -e
set -u


$SCRIPT_DIR/update_frontend_global_requirements.sh

cd "$FRONTEND_DIR"
$SCRIPT_DIR/update_frontend_local_requirements.sh

cd "$COMPONENTS_DIR"
$SCRIPT_DIR/update_frontend_local_requirements.sh
