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
fallocate -l 125MB $IMG

# partitions
parted -s $IMG mklabel gpt
parted -s $IMG mkpart primary ext4 16M 100%
dd if=sources/unpacked/u-boot.itb of=$IMG seek=16384 conv=notrunc

LOOP="$(losetup --find --partscan --show $IMG)"
mkfs.ext4 ${LOOP}p1

# outputs
mkdir $TMP/rootfs
mkdir $TMP/mnt
mount ${LOOP}p1 $TMP/mnt

rootfs/build.fish --mode root --dir $TMP/rootfs

cp $PWD/sources/unpacked/rock-5b-plus.dtb $TMP/mnt
cp $PWD/sources/unpacked/fan-control.dtbo $TMP/mnt
cp $PWD/sources/unpacked/Image $TMP/mnt

(cd $TMP/rootfs && find . | cpio --create --format newc | zstd > $TMP/alpine-initramfs.cpio.zst)
mkimage \
	--architecture arm64 \
	--type ramdisk \
	--compression zstd \
	--image $TMP/alpine-initramfs.cpio.zst $TMP/mnt/uInitrd

cat << 'EOF' > $TMP/boot.txt
setenv bootargs console=ttyS0,1500000n8 rootflags=size=1G

setenv kernel_addr 0x00400000
setenv fdt_addr 0x08300000
setenv fdto_addr 0x083c0000
setenv ramdisk_addr 0x0a200000

ext4load mmc 1:1 ${kernel_addr} /Image
ext4load mmc 1:1 ${fdt_addr} /rock-5b-plus.dtb
ext4load mmc 1:1 ${fdto_addr} /fan-control.dtbo
ext4load mmc 1:1 ${ramdisk_addr} /uInitrd

fdt addr ${fdt_addr}
fdt resize 512
fdt apply ${fdto_addr}

booti ${kernel_addr} ${ramdisk_addr} ${fdt_addr}
EOF
mkimage --architecture arm64 --type script --image $TMP/boot.txt $TMP/mnt/boot.scr

echo "image done, written to $IMG"
