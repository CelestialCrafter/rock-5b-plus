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
fallocate -l 150MB $IMG

# partitions
parted -s $IMG mklabel gpt
parted -s $IMG mkpart primary ext4 16M 100%

LOOP="$(losetup --find --partscan --show $IMG)"
echo "loop: $LOOP"
mkfs.ext4 ${LOOP}p1

dd if=sources/unpacked/u-boot.itb of=$IMG seek=16384 conv=notrunc

# rootfs
SETTINGS="rootfs/settings.json"

mkdir $TMP/rootfs
cp -ra sources/unpacked/alpine/* $TMP/rootfs
cp -a rootfs/init $TMP/rootfs

apk add --arch aarch64 --root $TMP/rootfs $(cat rootfs/packages) || true

awk \
    -v ssid="$(jq -r '.wifi.ssid' $SETTINGS)" \
    -v pw="$(jq -r '.wifi.password' $SETTINGS)" \
    '{gsub(/SSID/, ssid); gsub(/PASSWORD/, pw)}1' \
     rootfs/wpa_supplicant.conf > $TMP/rootfs/etc/wpa_supplicant.conf

echo "celestial:$(jq -r ".hashed_password"):::::::"
echo "celestial-homelab" > $TMP/rootfs/etc/hostname
echo "celestial:x:1000:1000::/home/celestial:/bin/sh" >> $TMP/rootfs/etc/passwd
cp rootfs/inittab $TMP/rootfs/etc/inittab

# outputs
mkdir $TMP/mnt
mount ${LOOP}p1 $TMP/mnt

cp -a $PWD/sources/unpacked/rock-5b-plus.dtb $TMP/mnt
cp -a $PWD/sources/unpacked/Image $TMP/mnt

(cd $TMP/rootfs && find . | cpio --create --format newc | gzip > $TMP/alpine-initramfs.cpio.gz)
mkimage \
	--architecture arm64 \
	--type ramdisk \
	--compression gzip \
	--image $TMP/alpine-initramfs.cpio.gz $TMP/mnt/uInitrd

cat << EOF > $TMP/boot.txt
ext4load mmc 1:1 ${ramdisk_addr_r} /uInitrd
ext4load mmc 1:1 ${kernel_addr_r} /Image
ext4load mmc 1:1 ${fdt_addr_r} /rock-5b-plus.dtb
booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
EOF
mkimage -T script -d $TMP/boot.txt $TMP/mnt/boot.scr

echo "image done, written to $IMG"
