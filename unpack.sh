#!/bin/sh
set -e

# setup
TMP="$(mktemp --directory)"
echo "unpacking tmp dir: $TMP"
mkdir -p sources/unpacked

cleanup() {
	losetup --detach-all
	umount $TMP/mnt
    rm -rf $TMP
}

trap cleanup EXIT

# u-boot
dpkg-deb -x sources/packed/u-boot.deb $TMP/u-boot
cp $TMP/u-boot/usr/lib/u-boot/rock-5b-plus/u-boot.itb sources/unpacked

# kernel
mkdir $TMP/mnt
LOOP="$(losetup --find --partscan --show sources/packed/armbian.img)"
mount ${LOOP}p1 $TMP/mnt

cp $TMP/mnt/boot/Image sources/unpacked/Image
cp $TMP/mnt/boot/dtb/rockchip/rk3588-radxa-rock-5b+.dtb sources/unpacked/rock-5b-plus.dtb
cp -r $TMP/mnt/lib/modules sources/unpacked
dtc -@ -I dts -O dtb -o sources/unpacked/fan-control.dtbo sources/packed/fan-control.dtso

# alpine
mkdir -p sources/unpacked/alpine
tar -xzf sources/packed/alpine.tar.gz -C sources/unpacked/alpine
