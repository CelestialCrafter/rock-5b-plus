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

IMG="rock-5b-plus.img"
rm $IMG || true
fallocate -l 750MiB $IMG

# partitions
parted -s $IMG mklabel gpt
parted -s $IMG mkpart primary ext4 16M 100%

LOOP="$(losetup --find --partscan --show $IMG)"
echo "loop: $LOOP"
mkfs.ext4 ${LOOP}p1

dd if=sources/unpacked/u-boot.itb of=$IMG seek=16384 conv=notrunc

# outputs
mkdir $TMP/mnt
mount ${LOOP}p1 $TMP/mnt

cp -a $PWD/sources/unpacked/rock-5b-plus.dtb $TMP/mnt
cp -a $PWD/sources/unpacked/Image $TMP/mnt

mkimage \
	--architecture arm64 \
	--type ramdisk \
	--compression zstd \
	--image sources/unpacked/initramfs.cpio.zst $TMP/mnt/uInitrd

cat << EOF > $TMP/boot.txt
ext4load mmc 1:1 ${ramdisk_addr_r} /uInitrd
ext4load mmc 1:1 ${kernel_addr_r} /Image
ext4load mmc 1:1 ${fdt_addr_r} /rock-5b-plus.dtb
booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
EOF
mkimage -T script -d $TMP/boot.txt $TMP/mnt/boot.scr

echo "image done, written to $IMG"
