IMAGE := chip-alpine-build
VERSION ?= $(shell git describe --tags --always)
RUN := podman run --rm -v $(CURDIR):/work:Z -w /work $(IMAGE)

.PHONY: container sources uboot kernel initramfs data image test release

container:
	podman build -t $(IMAGE) -f Containerfile .

sources:
	$(RUN) sources/fetch.sh

uboot: sources
	$(RUN) uboot/build.sh

kernel: sources
	$(RUN) kernel/build.sh

initramfs: kernel
	$(RUN) initramfs/build.sh

data: container
	$(RUN) data/build.sh

image: uboot kernel initramfs
	$(RUN) image/build.sh

test:
	$(RUN) bats tests

release:
	rm -rf build/release
	$(RUN) release/build.sh '$(VERSION)' build/release
