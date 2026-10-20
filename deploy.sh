#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$0")"

TARGET="${1:-green}"
PROXY="bg-proxy"
BASE_URL="http://127.0.0.1:18080"
CONFIG="nginx/default.conf"

case "$TARGET" in
  blue)
    EXPECTED_VERSION="v1"
    ;;
  green)
    EXPECTED_VERSION="v2"
    ;;
  *)
    echo "Usage: ./deploy.sh [blue|green]"
    exit 1
    ;;
esac

echo "==> Checking $TARGET application health..."

if ! docker exec "$PROXY" wget -qO- \
  "http://${TARGET}:3000/health" | grep -q "\"version\":\"${EXPECTED_VERSION}\""; then
  echo "ERROR: $TARGET is unhealthy. Traffic was not changed."
  exit 1
fi

BACKUP="$(mktemp)"
cp "$CONFIG" "$BACKUP"

restore_config() {
  echo "==> Deployment failed. Restoring previous configuration..."
  cp "$BACKUP" "$CONFIG"

  if docker exec "$PROXY" nginx -t; then
    docker exec "$PROXY" nginx -s reload || true
  fi

  rm -f "$BACKUP"
}

trap 'restore_config' ERR

echo "==> Switching traffic to $TARGET..."

python3 - "$CONFIG" "$TARGET" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
target = sys.argv[2]
content = path.read_text()

import re
updated, count = re.subn(
    r'proxy_pass http://(?:blue|green):3000;',
    f'proxy_pass http://{target}:3000;',
    content
)

if count != 1:
    raise SystemExit(f"Expected one proxy_pass directive, found {count}.")

path.write_text(updated)
PY

docker exec "$PROXY" nginx -t
docker exec "$PROXY" nginx -s reload

echo "==> Verifying active version..."

ACTUAL_VERSION=""
for attempt in 1 2 3 4 5; do
  ACTUAL_VERSION="$(curl -fsS "$BASE_URL/" |
    python3 -c 'import json,sys; print(json.load(sys.stdin).get("version",""))')" \
    && [[ "$ACTUAL_VERSION" == "$EXPECTED_VERSION" ]] && break
  sleep 1
done

if [[ "$ACTUAL_VERSION" != "$EXPECTED_VERSION" ]]; then
  echo "ERROR: Expected $EXPECTED_VERSION, got ${ACTUAL_VERSION:-no response}."
  false
fi

trap - ERR
rm -f "$BACKUP"

echo "SUCCESS: Traffic is now routed to $TARGET ($EXPECTED_VERSION)."
