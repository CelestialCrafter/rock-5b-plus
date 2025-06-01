#!/bin/sh
set -e

# setup
TMP="$(mktemp --directory)"
echo "unpacking tmp dir: $TMP"
mkdir -p sources/unpacked

cleanup() {
    rm -rf $TMP
}

trap cleanup EXIT

# u-boot
dpkg-deb -x sources/packed/u-boot.deb $TMP/u-boot
cp $TMP/u-boot/usr/lib/u-boot/rock-5b-plus/u-boot.itb sources/unpacked/

# kernel
dpkg-deb -x sources/packed/kernel.deb $TMP/kernel
cp -ra $TMP/kernel/boot/vmlinuz-* sources/unpacked/vmlinux.bin.gz
cp -ra $TMP/kernel/usr/lib/linux-image-*/rockchip/rk3588-rock-5b-plus.dtb \
    sources/unpacked/rock-5b-plus.dtb

# alpine
mkdir -p sources/unpacked/alpine/
tar -xzf sources/packed/alpine.tar.gz -C sources/unpacked/alpine/
