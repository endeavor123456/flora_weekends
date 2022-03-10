#!/bin/sh

set -e
set -x

if [ -z "$ARGOCD_TOKEN" ]; then
    echo 'env ARGOCD_TOKEN not set'
    exit 1
fi

SCRIPTS=$(cat << 'EOF'
curl "https://argocd.k.applysquare.net/api/v1/applications/${ARGOCD_NAMESPACE}-${ARGOCD_APPNAME}/resource?name=${ARGOCD_APPNAME}-frontend-0&namespace=${ARGOCD_NAMESPACE}&resourceName=${ARGOCD_APPNAME}-frontend-0&version=v1&kind=Pod&force=false" \
  -X DELETE \
  --cookie "argocd.token=$ARGOCD_TOKEN"
EOF
)

echo "$SCRIPTS" | docker run --rm -i \
  -e ARGOCD_NAMESPACE -e ARGOCD_APPNAME -e ARGOCD_TOKEN \
  applysq/toolbox:latest sh
