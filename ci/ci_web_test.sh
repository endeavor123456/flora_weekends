#!/bin/bash
# Test flora websites

set -e

export MY_UID=$(id -u)
export MY_GID=$(id -g)
export FLORA_SRC="$PWD/.."
export FLOAT_SRC="$FLORA_SRC/float"

# Path of float config
if [ -z "$FLOAT_PATH" ]; then
  echo "[ci_test] FLOAT_PATH undefined!"
  exit 1
fi

# Base url field to be written into configs
if [ -z "$FLOAT_BASE" ]; then
  echo "[ci_test] FLOAT_BASE undefined"
  exit 1
fi

# Absolute path of configs
FLOAT_FULL_PATH=$FLORA_SRC/$FLOAT_PATH

if [ ! -f "$FLOAT_FULL_PATH" ]; then
  echo "[ci_test] Cannot find $FLOAT_FULL_PATH"
  exit 1
fi

FLOAT_FILE_NAME=${FLOAT_FULL_PATH##*/}
export FLOAT_TARGET=${FLOAT_FILE_NAME%%.yaml}

echo "[ci_test] Test [$FLOAT_BASE] with testing patterns [$FLOAT_TARGET]"

# Prepare for the flora-base browsing environments
mkdir -p $FLOAT_SRC/output
mkdir -p $FLOAT_SRC/configs
cp "$FLOAT_FULL_PATH" "$FLOAT_SRC/configs/$FLOAT_FILE_NAME"
sed -i "/baseurl/c baseurl: $FLOAT_BASE" $FLOAT_SRC/configs/$FLOAT_TARGET.yaml

# Pull float container and run testing
echo "[ci_test] Run float in container..."
cd $FLORA_SRC/ci/ci_compose
docker-compose -f docker-compose.float.yml pull
if [ -f "$FLOAT_LOG" ] && [ "$FLOAT_LOG" = "on" ]; then
  docker-compose -f docker-compose.float.yml run --rm \
    -v ${FLOAT_SRC}/output/log:/float/output/log \
    -v ${FLOAT_SRC}/output/images:/float/output/images \
    float
# No logs generated by default
else
  docker-compose -f docker-compose.float.yml run --rm float
fi
echo "[ci_test] Test finished."
  