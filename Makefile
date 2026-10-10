IMAGE := chip-alpine-build
RUN := podman run --rm -v $(CURDIR):/work:Z -w /work $(IMAGE)

.PHONY: container test

container:
	podman build -t $(IMAGE) -f Containerfile .

test:
	$(RUN) bats tests
