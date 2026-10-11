#!/bin/sh
set -eu
cd "$(dirname "$0")/.."

CACHE=$PWD/build/out/data/cache
ROOT=$PWD/build/data-root
MAIN=https://dl-cdn.alpinelinux.org/alpine/v3.24/main
COMMUNITY=https://dl-cdn.alpinelinux.org/alpine/v3.24/community

rm -rf "$CACHE" "$ROOT"
mkdir -p "$CACHE" "$ROOT"
apk add --root "$ROOT" --arch armv7 --initdb --no-scripts \
	--keys-dir /usr/share/apk/keys/armv7 --cache-dir "$CACHE" \
	--repository "$MAIN" --repository "$COMMUNITY" \
	$(cat data/world)
rm -rf "$ROOT"
