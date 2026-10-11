setup_file() {
	export RELEASE=$(mktemp -d)
	release/build.sh test "$RELEASE"
}

teardown_file() {
	rm -rf "$RELEASE"
}

files() {
	tar -tzf "$RELEASE/chip-alpine-test.tar.gz" | grep -v '/$'
}

extract() {
	dir=$(mktemp -d)
	tar -xzf "$RELEASE/chip-alpine-test.tar.gz" -C "$dir"
	BUNDLE=$dir/chip-alpine-test
}

@test "release is the bundle and its checksum" {
	[ "$(ls "$RELEASE" | tr '\n' ' ')" = "chip-alpine-test.tar.gz chip-alpine-test.tar.gz.sha256 " ]
	(cd "$RELEASE" && sha256sum -c chip-alpine-test.tar.gz.sha256)
}

@test "release bundle extracts to a directory named after the version" {
	[ -z "$(tar -tzf "$RELEASE/chip-alpine-test.tar.gz" | grep -v '^chip-alpine-test/')" ]
}

@test "release bundle holds the flashing tools, the system data and the build outputs flashing reads" {
	diff - <(files | sed 's#^chip-alpine-test/##' | grep -v -e '^build/out/data/cache/' -e '^data/overlay/' | sort) <<-EOF
	LICENSE
	README.md
	build/out/boot-ram.scr
	build/out/chip.itb
	build/out/flash-uboot.scr
	build/out/sunxi-spl-with-ecc.bin
	build/out/u-boot-sunxi-with-spl.bin
	build/out/uboot-4m.bin
	data/apkovl.sh
	data/settings.sh
	data/world
	flash/99-chip-fel.rules
	flash/chip-put
	flash/chip-sh
	flash/fel-boot-ram.sh
	flash/fel-flash-uboot.sh
	flash/fel-run.sh
	flash/flash-nand.sh
	flash/flash-setup.sh
	flash/wait-for-console.sh
	EOF
}

@test "release bundle holds the system overlay and the apk cache" {
	diff <(cd data/overlay && find . -type f | sed 's#^\./##' | sort) \
		<(files | sed -n 's#^chip-alpine-test/data/overlay/##p' | sort)
	diff <(cd build/out/data/cache && find . -type f | sed 's#^\./##' | sort) \
		<(files | sed -n 's#^chip-alpine-test/build/out/data/cache/##p' | sort)
	files | grep -q '^chip-alpine-test/build/out/data/cache/APKINDEX\..*\.tar\.gz$'
}

@test "release bundle leaves out the sources and the build tree" {
	run grep -E '^chip-alpine-test/(Makefile|Containerfile|tests|sources|uboot|kernel|initramfs|image|release|data/build\.sh|build/(src|dl|kernel|uboot|modules|initramfs))' <(files)
	[ "$status" -eq 1 ]
}

@test "flash runs unchanged from the extracted release bundle" {
	extract
	for script in "$BUNDLE"/flash/*.sh "$BUNDLE"/flash/chip-put "$BUNDLE"/data/apkovl.sh; do
		[ -x "$script" ]
		sh -n "$script"
	done
	XDG_CONFIG_HOME=$(mktemp -d) run "$BUNDLE/flash/flash-nand.sh" --hostname garage --print-settings
	[ "$status" -eq 0 ]
	[ "${lines[0]}" = hostname=garage ]
}

@test "the extracted release bundle writes the system overlay" {
	extract
	out=$(mktemp -d)
	"$BUNDLE/data/apkovl.sh" "$out" --hostname garage
	tar -xzOf "$out/garage.apkovl.tar.gz" etc/apk/world | grep -qx openssh
}

@test "release bundle belongs to root" {
	[ -z "$(tar -tzvf "$RELEASE/chip-alpine-test.tar.gz" | grep -v ' root/root ')" ]
}

@test "release needs a version and a directory" {
	run release/build.sh test
	[ "$status" -eq 2 ]
	[[ "$output" == *usage* ]]
}
