# shellcheck shell=bash
ROOT_DIR=$( dirname $( dirname "$SCRIPT_DIR" ) )
COMPONENTS_DIR="$ROOT_DIR/components"
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
