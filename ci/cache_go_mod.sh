#!/bin/sh

set -e

GO_MOD_DIR=${1:-$PWD/..}
GOPATH_CACHE=${GOPATH_CACHE:-/tmp/cache/gopath}
GOBUILD_CACHE=${GOBUILD_CACHE:-/tmp/cache/gobuild}

KNOWN_HOSTS_PATH=${KNOWN_HOST_PATH:-$HOME/.ssh/known_hosts}
SSH_KEY_PATH=${SSH_KEY_PATH:-$HOME/.ssh/id_rsa}

F_SSH_KEY=$(cat "$SSH_KEY_PATH")
export F_SSH_KEY
F_KNOWN_HOSTS=$(cat "$KNOWN_HOSTS_PATH")
export F_KNOWN_HOSTS

mkdir -p "$GOPATH_CACHE"

SCRIPTS=$(
                cat <<'EOF'
set -e
echo Caching go modules.

mkdir -p /etc/git-secret
echo "${F_SSH_KEY}" > /etc/git-secret/ssh
echo "${F_KNOWN_HOSTS}" > /etc/git-secret/known_hosts
chmod 400 /etc/git-secret/*

export GIT_SSH_COMMAND="ssh -q -o UserKnownHostsFile=/etc/git-secret/known_hosts -i /etc/git-secret/ssh"
export GO111MODULE=on
export GOPROXY=https://goproxy.cn,direct
export GOPRIVATE="*.applysquare.*"
git config --system url."ssh://git@ma.applysquare.net/".insteadOf "https://ma.applysquare.net/"

mkdir -p /flora/src
cp /flora/src_stage/go.mod /flora/src/go.mod
cd /flora/src
mkdir -p /flora/src/stage/pool
cd /flora/src/stage/pool
go mod init ma.applysquare.net/eng/flora/pkg/core/gen || true
cd /flora/src
go mod edit -replace ma.applysquare.net/eng/flora/pkg/core/gen=./stage/pool
cp /flora/src_stage/go.sum /flora/src/go.sum

cd /flora/src
go mod download
echo Caching go modules done.
EOF
        )

[ $FLORA_FORCE_PULL_IMAGE = "1" ] && docker pull ma.applysquare.net:4567/eng/flora/flora-builder-go:1.16-buster
echo "$SCRIPTS" | docker run -i --rm \
  -e F_SSH_KEY \
  -e F_KNOWN_HOSTS \
  -v "$GO_MOD_DIR:/flora/src_stage:delegated" \
  -v "$GOPATH_CACHE:/goext:delegated" \
  -v "$GOBUILD_CACHE:/tmp/cache/gobuild:delegated" \
  -e GOPATH=/goext \
  -e GOCACHE=/tmp/cache/gobuild \
  ma.applysquare.net:4567/eng/flora/flora-builder-go:1.16-buster sh
