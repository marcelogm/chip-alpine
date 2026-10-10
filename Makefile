IMAGE := chip-alpine-build
RUN := podman run --rm -v $(CURDIR):/work:Z -w /work $(IMAGE)

.PHONY: container sources uboot kernel initramfs image test fel-boot

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

image: uboot kernel initramfs
	$(RUN) image/build.sh

test:
	$(RUN) bats tests

fel-boot:
	dev/fel-boot-ram.sh
