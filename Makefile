IMAGE := chip-alpine-build
RUN := podman run --rm -v $(CURDIR):/work:Z -w /work $(IMAGE)

.PHONY: container sources uboot kernel initramfs data image test

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

image: uboot kernel initramfs data
	$(RUN) image/build.sh

test:
	$(RUN) bats tests
