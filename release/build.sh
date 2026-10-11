#!/bin/sh
set -eu
caller=$PWD
cd "$(dirname "$0")/.."

OUTPUTS="u-boot-sunxi-with-spl.bin sunxi-spl-with-ecc.bin uboot-4m.bin flash-uboot.scr boot-ram.scr chip.itb"

usage() {
	echo "usage: $0 VERSION OUT_DIR" >&2
	exit 2
}

missing() {
	echo "$1 is missing: run make $2" >&2
	exit 1
}

[ $# -eq 2 ] || usage
[ -n "$1" ] || usage
NAME=chip-alpine-$1
case $2 in
/*) OUT_DIR=$2 ;;
*) OUT_DIR=$caller/$2 ;;
esac

for file in $OUTPUTS; do
	[ -f "build/out/$file" ] || missing "build/out/$file" image
done
ls build/out/data/cache/APKINDEX.*.tar.gz > /dev/null 2>&1 || missing build/out/data/cache data

STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
BUNDLE=$STAGE/$NAME

mkdir -p "$BUNDLE/data" "$BUNDLE/build/out/data"
cp README.md LICENSE "$BUNDLE/"
cp -R flash "$BUNDLE/"
cp -R data/apkovl.sh data/settings.sh data/world data/overlay "$BUNDLE/data/"
for file in $OUTPUTS; do
	cp "build/out/$file" "$BUNDLE/build/out/"
done
cp -R build/out/data/cache "$BUNDLE/build/out/data/"

mkdir -p "$OUT_DIR"
tar -czf "$OUT_DIR/$NAME.tar.gz" --owner=0 --group=0 -C "$STAGE" "$NAME"
(cd "$OUT_DIR" && sha256sum "$NAME.tar.gz" > "$NAME.tar.gz.sha256")
