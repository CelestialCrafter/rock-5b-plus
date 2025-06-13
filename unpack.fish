#!/usr/bin/env fish

# setup
set tmp (mktemp --directory)
echo "unpacking tmp dir: $tmp"
mkdir -p sources/unpacked

function cleanup
	losetup --detach-all
	umount $tmp/mnt
    rm -rf $tmp
end

trap cleanup EXIT

# u-boot
dpkg-deb -x sources/packed/u-boot.deb $tmp/u-boot
cp $tmp/u-boot/usr/lib/u-boot/rock-5b-plus/u-boot.itb sources/unpacked

# kernel
mkdir $tmp/mnt
set loop (losetup --find --partscan --show sources/packed/armbian.img)
mount {$loop}p1 $tmp/mnt

cp $tmp/mnt/boot/Image sources/unpacked/Image
cp $tmp/mnt/boot/dtb/rockchip/rk3588-radxa-rock-5b+.dtb sources/unpacked/rock-5b-plus.dtb
cp -r $tmp/mnt/lib/modules sources/unpacked
dtc -@ -I dts -O dtb -o sources/unpacked/fan-control.dtbo sources/packed/fan-control.dtso

# alpine
mkdir -p sources/unpacked/alpine
tar -xzf sources/packed/alpine.tar.gz -C sources/unpacked/alpine
