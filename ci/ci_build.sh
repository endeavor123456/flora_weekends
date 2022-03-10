#!/bin/sh

set -e
set -x

if [ -z "$FLORA_BUILD_PROJECT_DIR" ]; then
  echo 'env FLORA_BUILD_PROJECT_DIR not set'
  exit 1
fi
if [ -z "$FLORA_BUILD_IMAGE" ]; then
  echo 'env FLORA_BUILD_IMAGE not set'
  exit 1
fi
export FLORA_APP_DIR="$PWD/.."
export FLORA_BUILD_DIST="$FLORA_APP_DIR/tmp/dist"
mkdir -p "$FLORA_BUILD_DIST"
export GOPATH_CACHE=/tmp/cache/gopath
export GOBUILD_CACHE=/tmp/cache/gobuild
export YARN_CACHE=/tmp/cache/yarn

set +x
KNOWN_HOSTS_PATH=${KNOWN_HOST_PATH:-$HOME/.ssh/known_hosts}
SSH_KEY_PATH=${SSH_KEY_PATH:-$HOME/.ssh/id_rsa}

F_SSH_KEY=$(cat "$SSH_KEY_PATH")
export F_SSH_KEY
F_KNOWN_HOSTS=$(cat "$KNOWN_HOSTS_PATH")
export F_KNOWN_HOSTS
set -x

cp $FLORA_APP_DIR/$FLORA_BUILD_PROJECT_DIR/flora.toml $FLORA_BUILD_DIST/flora.toml

mkdir -p "$YARN_CACHE"

sh cache_go_mod.sh "$PWD/.."

BUILD_GO_SCRIPTS=$(
  cat <<'EOF'
set -e
set -x

groupadd -g $MY_GID -o mygroup
useradd -m -u $MY_UID -g $MY_GID -o -s /bin/sh myuser

mkdir -p /flora/dist
chown myuser.mygroup /flora/dist

rsync -r --exclude=node_modules --exclude=.git --exclude=stage --exclude=tmp \
  /flora/src_stage/ /flora/src

ls /flora/src
export GOBIN=/bin

PROJECT_DIR=/flora/src/$FLORA_BUILD_PROJECT_DIR

mkdir -p $PROJECT_DIR/stage/pool
cd $PROJECT_DIR/stage/pool
go mod init ma.applysquare.net/eng/flora/pkg/core/gen || true

cd $PROJECT_DIR
echo Building flora cli.
go install ma.applysquare.net/eng/flora/cmd/flora
echo Building flora cli done.

flora generate
flora build

sudo -u myuser mkdir -p /flora/dist/stage/bin
sudo -u myuser cp stage/bin/appserver /flora/dist/stage/bin/appserver
sudo -u myuser mkdir -p /flora/dist/stage/node
sudo -u myuser cp -r stage/node/fumi /flora/dist/stage/node/fumi_src
sudo -u myuser mkdir -p /flora/dist/stage/res
rm -rf /flora/dist/stage/res
chmod a+rx /goext/pkg/mod/ma.applysquare.net/eng/*
sudo -u myuser cp -rL stage/res /flora/dist/stage/res
sudo -u myuser chmod -R u+w /flora/dist/stage/res
EOF
)

MY_UID=$(id -u)
export MY_UID
MY_GID=$(id -g)
export MY_GID

cd ci_compose
docker-compose -f docker-compose.build.yml pull
echo "$BUILD_GO_SCRIPTS" | docker-compose -f docker-compose.build.yml run --rm \
  -e MY_UID \
  -e MY_GID \
  -e GOPATH=/goext \
  -e GOCACHE=/tmp/cache/gobuild \
  -e FLORA_BUILD_PROJECT_DIR \
  go sh

BUILD_NODE_SCRIPTS=$(
  cat <<'EOF'
set -e
set -x

groupadd -g $MY_GID -o mygroup
useradd -m -u $MY_UID -g $MY_GID -o -s /bin/sh myuser

mkdir -p /etc/git-secret
set +x
echo "${F_SSH_KEY}" > /etc/git-secret/ssh
echo "${F_KNOWN_HOSTS}" > /etc/git-secret/known_hosts
set -x
chmod 400 /etc/git-secret/*
chown myuser.mygroup /etc/git-secret/*
export GIT_SSH_COMMAND="ssh -vvv -o UserKnownHostsFile=/etc/git-secret/known_hosts -i /etc/git-secret/ssh"

sudo chown myuser.mygroup $YARN_CACHE_FOLDER

cd /flora/dist/stage/node/fumi_src

sed -i 's/resolved "https:\/\/registry.yarnpkg.com/resolved "https:\/\/registry.npm.taobao.org/' yarn.lock
sudo -u myuser yarn config set registry https://registry.npm.taobao.org --global
sudo -u myuser yarn config set disturl https://npm.taobao.org/dist --global
sudo -u myuser yarn config list

sudo GIT_SSH_COMMAND="$GIT_SSH_COMMAND" -u myuser yarn --network-timeout=100000
sudo -u myuser yarn build

sudo -u myuser mkdir -p /flora/dist/stage/node/fumi/src
sudo -u myuser mkdir -p /flora/dist/stage/node/fumi/config
cd /flora/dist/stage/node/fumi
cp /flora/dist/stage/node/fumi_src/server.js ./server.js
cp /flora/dist/stage/node/fumi_src/config/proxy-config.js ./config/proxy-config.js
cp /flora/dist/stage/node/fumi_src/src/html-to-docx.cjs.js ./src/html-to-docx.cjs.js
sudo -u myuser  cp -r /flora/dist/stage/node/fumi_src/dist ./dist

sudo -u myuser cat > package.json <<EOL
{
  "private": true,
  "dependencies": {
		"@umijs/utils": "3.2.14",
    "koa": "^2.7.0",
    "koa-compress": "^3.0.0",
    "koa-mount": "^4.0.0",
    "koa-pino-logger": "^2.1.3",
    "koa-static": "^5.0.0",
		"koa-router": "10.0.0",
    "koa-bodyparser": "4.3.0",
    "koa2-proxy-middleware": "0.0.4",
    "color-name": "1.1.4",
    "escape-html": "1.0.3",
    "html-minifier": "4.0.0",
    "html-to-vdom": "0.7.0",
    "image-size": "0.8.3",
    "jszip": "3.5.0",
    "virtual-dom": "2.1.1",
    "xmlbuilder2": "2.1.2",
    "regenerator-runtime": "^0.13.2",
		"pm2": "5.1.0",
    "umi-server": "^1.0.0"
  }
}
EOL

sudo -u myuser yarn
EOF
)

echo "$BUILD_NODE_SCRIPTS" | docker-compose -f docker-compose.build.yml run --rm \
  -e MY_UID \
  -e MY_GID \
  -e F_SSH_KEY \
  -e F_KNOWN_HOSTS \
  -e YARN_CACHE_FOLDER=/tmp/cache/yarn \
  -e FLORA_BUILD_PROJECT_DIR \
  node sh

cd "$FLORA_BUILD_DIST"

cat > .dockerignore <<EOL
stage/node/fumi_src
EOL

ls ./stage/res/static > /dev/null

cat > Dockerfile <<EOL
FROM applysq/flora-runtime-oracle-client:2

WORKDIR /flora/release

COPY ./stage/bin/appserver /flora/release/stage/bin/appserver
COPY ./stage/node/fumi /flora/release/stage/node/fumi
COPY ./stage/res /flora/release/stage/res
COPY ./flora.toml /flora/release/flora.toml
EOL

docker pull applysq/flora-runtime-oracle-client:2
docker build -t "$FLORA_BUILD_IMAGE" .
docker push "$FLORA_BUILD_IMAGE"  
docker rmi "$FLORA_BUILD_IMAGE"
rm -rf $FLORA_BUILD_DIST
