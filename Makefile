KERNEL_VERSION=3.18.11
QEMU_VERSION=2.2.1
CURL_VERSION=7.20.0
BUSYBOX_VERSION=1.16.0
MAKE_OPTS=-j4

prefix=${PWD}/dist

all: dist/lib/initramfs dist/lib/linux dist/bin/qemu-system-x86_64 dist/bin/qemu-extract-image dist/bin/curl 

clean:
	rm -Rf build dist

dist/lib/initramfs: dist/lib/linux dist/bin/busybox
	BUSYBOX_BINARY=${prefix}/bin/busybox INIT_SCRIPT=${PWD}/init.sh build/linux/usr/gen_init_cpio initramfs.cpio-list > $@

dist/bin/qemu-system-x86_64: build/qemu
	(cd build/qemu && PATH=${prefix}/bin:${PATH} ./configure --prefix=${prefix} --target-list=x86_64-softmmu --enable-virtfs && make ${MAKE_OPTS} && make install)

dist/bin/qemu-extract-image: qemu-extract-image.sh
	cp $< $@

dist/bin/curl: build/curl
	(cd build/curl && ./configure --prefix=${prefix} && make ${MAKE_OPTS} && make install)

dist/lib/linux: build/linux-${KERNEL_VERSION}
	cp linux-config-x86_64 build/linux/.config
	(cd build/linux && make bzImage ${MAKE_OPTS})
	mkdir -p dist/lib
	cp build/linux/arch/x86/boot/bzImage $@

dist/bin/busybox: build/busybox
	cp busybox-config build/busybox/.config
	(cd build/busybox && make clean && make ${MAKE_OPTS})
	mkdir -p dist/bin
	cp build/busybox/busybox $@

build:
	mkdir -p build

build/curl: tarballs/curl-${CURL_VERSION}.tar.bz2 build
	tar -C build -jxf $<
	ln -fs curl-${CURL_VERSION} build/curl

build/qemu: tarballs/qemu-${QEMU_VERSION}.tar.bz2 build
	tar -C build -jxf $<
	ln -fs qemu-${QEMU_VERSION} build/qemu

build/linux-${KERNEL_VERSION}: tarballs/linux-${KERNEL_VERSION}.tar.gz build
	tar -C build -zxf $<
	ln -sf linux-${KERNEL_VERSION} build/linux

build/busybox: tarballs/busybox-${BUSYBOX_VERSION}.tar.bz2 build
	tar -C build -jxf $<
	ln -sf busybox-${BUSYBOX_VERSION} build/busybox

downloads: tarballs tarballs/qemu-${QEMU_VERSION}.tar.bz2 tarballs/linux-${KERNEL_VERSION}.tar.gz

tarballs/busybox-${BUSYBOX_VERSION}.tar.bz2:
	wget -c http://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2 -O $@

tarballs/curl-${CURL_VERSION}.tar.bz2:
	wget -c http://curl.haxx.se/download/curl-${CURL_VERSION}.tar.bz2 -O $@

tarballs/qemu-${QEMU_VERSION}.tar.bz2:
	wget -c http://wiki.qemu-project.org/download/qemu-${QEMU_VERSION}.tar.bz2 -O $@

tarballs/linux-${KERNEL_VERSION}.tar.gz:
	wget -c https://www.kernel.org/pub/linux/kernel/v3.x/linux-${KERNEL_VERSION}.tar.gz -O $@

tarballs:
	mkdir -p tarballs

.PHONY: downloads all dist
