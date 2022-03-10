#!/bin/sh

set -e

export FLORA_APP_DIR=$PWD/../
export GOPATH_CACHE=/tmp/cache/gopath
export GOBUILD_CACHE=/tmp/cache/gobuild
sh cache_go_mod.sh "$PWD/.."

EXTRA_SCRIPTS=$(cat ./ci_test_extra.sh || echo '')

if [ "$FLORA_SIMPLE_TEST" == "1" ]; then
# simple mode
TEST_SCRIPTS=$(cat <<'EOF'
echo Start go simple test.
go_test_start=$(date +%s)
go test -vet=off ./pkg/...
go_test_end=$(date +%s)
echo Go simple test done, used $((go_test_end - go_test_start)) seconds.

echo Flora lint start.
flora_lint_start=$(date +%s)
flora lint --simple
flora_lint_end=$(date +%s)
echo Flora lint done, used $((flora_lint_end - flora_lint_start)) seconds.
EOF
)
else 
# full mode
TEST_SCRIPTS=$(cat <<'EOF'
echo Start go full test.
go_test_start=$(date +%s)
go test -vet=off -race ./pkg/...
go_test_end=$(date +%s)
echo Go full test done, used $((go_test_end - go_test_start)) seconds.

echo Flora lint start.
flora_lint_start=$(date +%s)
flora lint
flora_lint_end=$(date +%s)
echo Flora lint done, used $((flora_lint_end - flora_lint_start)) seconds.
EOF
)
fi

SCRIPTS=$(cat <<'EOF'
set -e

cp -r /flora/src_stage /flora/src
rm -rf /flora/src/stage

export GOBIN=/bin

if [ -f "/flora/src/flora.toml" ]; then
  mkdir -p /flora/src/stage/pool
  cd /flora/src/stage/pool
  go mod init ma.applysquare.net/eng/flora/pkg/core/gen || true
fi

cd /flora/src
echo Building flora cli.
go install ma.applysquare.net/eng/flora/cmd/flora
echo Building flora cli done.

cd /flora/src
if [ -f "/flora/src/flora.toml" ]; then
  flora generate -t
fi
EOF
echo "$TEST_SCRIPTS"
echo "$EXTRA_SCRIPTS"
)

cd ci_compose
if [ $FLORA_ES_ENABLED == "1" ]; then
  # 启动带ES
  docker-compose -f docker-compose.test.yml -f docker-compose-es.test.yml pull
  echo "$SCRIPTS" | docker-compose -f docker-compose.test.yml -f docker-compose-es.test.yml run --rm \
    -e GOPATH=/goext \
    -e GOCACHE=/tmp/cache/gobuild \
    -e FLORA_DB_USER=postgres \
    -e FLORA_DB_PASSWORD=postgres \
    -e FLORA_DB_HOST=flora_test_postgres \
    -e FLORA_ES_HOST=flora_test_elastic \
    go sh
else
  # 启动默认
  docker-compose -f docker-compose.test.yml pull
  echo "$SCRIPTS" | docker-compose -f docker-compose.test.yml run --rm \
    -e GOPATH=/goext \
    -e GOCACHE=/tmp/cache/gobuild \
    -e FLORA_DB_USER=postgres \
    -e FLORA_DB_PASSWORD=postgres \
    -e FLORA_DB_HOST=flora_test_postgres \
    go sh
fi
