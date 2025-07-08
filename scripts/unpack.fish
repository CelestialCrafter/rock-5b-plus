#!/usr/bin/env fish

mkdir -p sources/unpacked
mkdir -p sources/packed

if test (id -u) -ne 0
	echo "effective uid is not 0, please run as root"
	exit 1
end

if test "$argv[1]" = "update"
# vars
	curl "https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/aarch64/alpine-minirootfs-3.22.0-aarch64.tar.gz" \
		-o sources/packed/alpine.tar.gz
	curl -L "https://dl.armbian.com/rock-5b-plus/Bookworm_edge_minimal" \
		-o sources/packed/armbian.img.xz
	xz -d armbian.img.xz

	echo "updated sources"
	exit
end

# setup
set tmp (mktemp --directory)
echo "unpacking tmp dir: $tmp"

function cleanup
    losetup --detach-all
    sudo umount $tmp/mnt
    rm -rf $tmp
end

trap cleanup EXIT

# u-boot
dpkg-deb -x sources/packed/u-boot.deb $tmp/u-boot
cp $tmp/u-boot/usr/lib/u-boot/rock-5b-plus/u-boot.itb sources/unpacked

# kernel
mkdir $tmp/mnt
mount (losetup --find --partscan --show sources/packed/armbian.img)p1 $tmp/mnt
or begin
	echo "could not mount image"
	echo "please rerun script until this error goes away"
	exit 1
end

cp $tmp/mnt/boot/Image sources/unpacked/Image
cp $tmp/mnt/boot/dtb/rockchip/rk3588-rock-5b-plus.dtb sources/unpacked/rock-5b-plus.dtb
cp -r $tmp/mnt/lib/modules sources/unpacked

# alpine
mkdir -p sources/unpacked/alpine
tar -xzf sources/packed/alpine.tar.gz -C sources/unpacked/alpine

echo "unpacked sources"
