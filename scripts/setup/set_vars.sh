# shellcheck shell=bash
ROOT_DIR=$( dirname $( dirname "$SCRIPT_DIR" ) )
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"
COMPONENTS_DIR="$ROOT_DIR/components"
EXTRACT_CMD="$ROOT_DIR/scripts/setup/extract_deployment_data.py"
NPM_PATH=`which npm`
VIRTUAL_ENV="${VIRTUAL_ENV}"

INSTANCE_TYPE="$1"

if [ -z "$INSTANCE_TYPE" ]
then
    INSTANCE_TYPE="localhost"
fi

if command -v gxargs > /dev/null; then
    XARGS_CMD="gxargs"
else
    XARGS_CMD="xargs"
fi
