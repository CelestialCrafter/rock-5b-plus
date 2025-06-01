#!/bin/sh
set -e

# setup
TMP="$(mktemp --directory)"
echo "image tmp dir: $TMP"

cleanup() {
	sync
	losetup --detach-all
	umount $TMP/mnt || true
    rm -rf $TMP
}

trap cleanup EXIT

IMG="alpine-out.img"
rm $IMG || true
fallocate -l 100MB $IMG

# partitions
parted -s $IMG mklabel gpt
parted -s $IMG mkpart primary ext4 16.8M 100%

LOOP="$(losetup --find --partscan --show $IMG)"
echo "loop: $LOOP"
mkfs.ext4 ${LOOP}p1

dd if=sources/unpacked/u-boot.itb of=$IMG seek=16384 conv=notrunc

# rootfs
mkdir $TMP/rootfs
cp -ra sources/unpacked/alpine/* $TMP/rootfs
find $TMP/rootfs | cpio --create --format newc | gzip > $TMP/rootfs/alpine-initramfs.cpio.gz

# for pkg in wpa_supplicant; do
# 	apk add --root $TMP/rootfs
# done
#
# cat rootfs/wpa_supplicant.conf | sed \
# 	-e "s/SSID/$(jq .wifi.ssid rootfs/settings.json)" \
# 	-e "s/PASSWORD/$(jq .wifi.password rootfs/settings.json)" > \
# 	/etc/wpa_supplicant/wpa_supplicant.conf

# FIT blob
# mkdir $TMP/incbin
# mv $TMP/rootfs/alpine-initramfs.cpio.gz $TMP/incbin/
# ln -s $PWD/sources/unpacked/rock-5b-plus.dtb $TMP/incbin/
# ln -s $PWD/sources/unpacked/vmlinux.bin.gz $TMP/incbin/
# ln -s $PWD/rock-5b-plus.its $TMP/incbin/

mkdir $TMP/mnt
mount ${LOOP}p1 $TMP/mnt
cp -a $PWD/sources/unpacked/rock-5b-plus.dtb $TMP/mnt/
mkimage --architecture arm64 --type ramdisk --compression gzip -a 0x0a200000 -e 0x0a200000 --image $TMP/rootfs/alpine-initramfs.cpio.gz $TMP/mnt/uInitrd
gzip -d -c $PWD/sources/unpacked/vmlinux.bin.gz > $TMP/mnt/vmlinux.bin

# cp $TMP/incbin/* $TMP/mnt/
# (cd $TMP/incbin && mkimage -f rock-5b-plus.its $TMP/mnt/rock-5b-plus.itb)

echo "image done, written to $IMG"
