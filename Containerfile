FROM docker.io/library/alpine:3.24

RUN apk add --no-cache \
	alpine-keys \
	bash \
	bats \
	bc \
	binutils-arm-none-eabi \
	bison \
	build-base \
	coreutils \
	cpio \
	curl \
	diffutils \
	dtc \
	elfutils-dev \
	findutils \
	flex \
	gcc-arm-none-eabi \
	gnutls-dev \
	gzip \
	kmod \
	linux-headers \
	ncurses-dev \
	openssl-dev \
	perl \
	py3-elftools \
	py3-libfdt \
	py3-setuptools \
	python3 \
	python3-dev \
	swig \
	tar \
	u-boot-tools \
	util-linux-dev \
	xz
