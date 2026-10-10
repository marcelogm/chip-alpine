IMAGE := chip-alpine-build
RUN := podman run --rm -v $(CURDIR):/work:Z -w /work $(IMAGE)

.PHONY: container sources test

container:
	podman build -t $(IMAGE) -f Containerfile .

sources:
	$(RUN) sources/fetch.sh

test:
	$(RUN) bats tests
